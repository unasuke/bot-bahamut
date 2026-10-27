require 'anthropic'
require_relative '../lib/ruboty/patches/discord_typing' unless ENV['LOCAL']
require_relative '../lib/tool_handlers/memories'
require_relative '../lib/tool_handlers/reminder'
require_relative '../lib/conversation_history'

module Ruboty
  module Actions
    class AiReply < Base
      MODEL = ENV.fetch('ANTHROPIC_MODEL', 'claude-haiku-5-5')
      # thinking のトークンも含まれるため、回答本文の分も見込んで余裕を持たせる
      MAX_TOKENS = 16_000
      DISCORD_MAX_LENGTH = 2000
      MAX_TOOL_CALLS = 10
      SYSTEM_PROMPT = <<~PROMPT
        あなたは友人同士が集まっているDiscordサーバーにいるbotです。
        日本語で、敬語で回答してください。絵文字はあまり使用しないでください。
        友人同士のカジュアルな会話環境であるため、定型的な敬語表現や定番の挨拶句は避け、敬語を保ちながらも直接的で自然な応答をしてください。
        'bahamut' はあなたの名前ですが、そこに意味はありません。回答する内容とbahamutという単語の意味は関連付ける必要はありません。
        あなた自身のソースコードは https://github.com/unasuke/bot-bahamut にて管理されています。
        あなた自身のモデルは #{MODEL} です。
      PROMPT

      def call(body)
        typing_thread = start_typing_loop

        channel_id = message.original[:from]
        @history = ConversationHistory.new(channel_id)
        @history_log = []

        user_content = "#{message.from_name || 'anonymous'}: #{body}"
        @history_log << { role: 'user', content: user_content }
        messages = @history.load + [{ role: 'user', content: user_content }]

        run_agentic_loop(messages)
      rescue Anthropic::Errors::APIError => e
        message.reply("API error: #{e.message}")
      ensure
        typing_thread&.kill
      end

      private

      def start_typing_loop
        return if ENV['LOCAL']

        channel = message.robot.adapter.bot.channel(message.original[:to])
        Thread.new do
          loop do
            channel.start_typing
            sleep 4
          end
        end
      end

      def run_agentic_loop(messages)
        collected_urls = []
        collected_codes = []
        reply_texts = []
        @sent_messages = []
        @sent_chunks = []

        MAX_TOOL_CALLS.times do
          request_params = {
            model: MODEL,
            max_tokens: MAX_TOKENS,
            system: "#{SYSTEM_PROMPT}\n現在の日時: #{Time.now.getlocal('+09:00').strftime('%Y-%m-%d %H:%M:%S JST')}",
            tools: tools,
            messages: messages
          }

          servers = mcp_servers
          unless servers.empty?
            request_params[:mcp_servers] = servers
            request_params[:betas] = ['mcp-client-2025-11-20']
          end

          response = if servers.empty?
                       client.messages.create(**request_params)
                     else
                       client.beta.messages.create(**request_params)
                     end

          pp response

          # Send text blocks immediately and collect URLs
          texts_this_response = []
          response.content.each do |block|
            texts_this_response << block.text if block.type == :text && !block.text.empty?
            collect_urls(block, collected_urls)
            collect_codes(block, collected_codes)
          end

          unless texts_this_response.empty?
            # 以前のレスポンスのテキストを残したまま追記する
            reply_texts.concat(texts_this_response)
            send_or_edit(reply_texts.join("\n"))
          end

          if response.stop_reason == :tool_use
            # Append assistant response with only API-accepted fields
            messages << { role: 'assistant', content: serialize_content(response.content) }

            # Process each tool use block
            tool_results = response.content
              .select { |block| block.type == :tool_use }
              .map { |tool_use| process_tool_use(tool_use) }

            messages << { role: 'user', content: tool_results }
          elsif response.stop_reason == :pause_turn
            # Resume paused turn (e.g. long-running web search)
            messages << { role: 'assistant', content: serialize_content(response.content) }
          else
            message.reply('（出力の上限に達したため、回答が途中で終了しています）') if response.stop_reason == :max_tokens
            send_urls_message(collected_urls)
            send_code_message(collected_codes)
            @history_log << { role: 'assistant', content: reply_texts.join("\n") } unless reply_texts.empty?
            @history.save(@history_log)
            return
          end
        end

        # Fallback if loop limit reached
        send_urls_message(collected_urls)
        message.reply('すみません、処理が複雑になりすぎました。もう一度お試しください。') if reply_texts.empty?
      end

      def mcp_servers
        return [] unless ENV['GITHUB_TOKEN']

        [
          {
            type: 'url',
            url: 'https://api.githubcopilot.com/mcp/',
            name: 'github',
            authorization_token: ENV.fetch('GITHUB_TOKEN')
          }
        ]
      end

      def tools
        base_tools = [
          { type: 'web_search_20250305', name: 'web_search', max_uses: 5 },
          { type: 'web_fetch_20250910', name: 'web_fetch', max_uses: 5 },
          { type: 'code_execution_20250825', name: 'code_execution' },
          { type: 'memory_20250818', name: 'memory' },
          {
            name: 'set_reminder',
            description: 'リマインダーを登録する。',
            input_schema: {
              type: 'object',
              properties: {
                hours: {
                  type: 'integer',
                  description: '何時間後か'
                },
                minutes: {
                  type: 'integer',
                  description: '何分後か'
                },
                seconds: {
                  type: 'integer',
                  description: '何秒後か'
                },
                text: {
                  type: 'string',
                  description: 'リマインダーの内容。ユーザー名や宛先は含めないこと。例: "30秒経過しました"、"ミーティングの時間です"'
                }
              },
              required: ['hours', 'minutes', 'seconds', 'text']
            }
          }
        ]

        if ENV['GITHUB_TOKEN']
          base_tools << {
            type: 'mcp_toolset',
            mcp_server_name: 'github',
            default_config: { enabled: false },
            configs: {
              # reposツールセット
              'get_file_contents'    => { enabled: true },
              'search_code'          => { enabled: true },
              'search_repositories'  => { enabled: true },
              'list_commits'         => { enabled: true },
              'get_commit'           => { enabled: true },
              'list_branches'        => { enabled: true },
              'get_repository_tree'  => { enabled: true },
              # issuesツールセット
              'list_issues'          => { enabled: true },
              'issue_read'           => { enabled: true },
              'search_issues'        => { enabled: true },
              # pull_requestsツールセット
              'list_pull_requests'   => { enabled: true },
              'pull_request_read'    => { enabled: true },
              'search_pull_requests' => { enabled: true },
              # actionsツールセット
              'actions_list'         => { enabled: true },
              'actions_get'          => { enabled: true },
              'get_job_logs'         => { enabled: true }
            }
          }
        end

        base_tools
      end

      # 文字数制限に収まるよう分割し、送信済みのものと内容が変わったチャンクだけ編集する。
      # 足りない分は新しいメッセージとして送信する
      def send_or_edit(text)
        split_message(text).each_with_index do |chunk, i|
          next if @sent_chunks[i] == chunk

          if ENV['LOCAL']
            message.reply(chunk)
          elsif @sent_messages[i]
            @sent_messages[i].edit(chunk)
          else
            channel = message.robot.adapter.bot.channel(message.original[:to])
            @sent_messages[i] = channel.send_message(chunk)
          end
          @sent_chunks[i] = chunk
        end
      end

      # テキストを limit 文字以下のチャンクに分割する。できるだけ改行位置で区切る
      def split_message(text, limit = DISCORD_MAX_LENGTH)
        chunks = []
        buffer = +''
        text.each_line do |line|
          if buffer.length + line.length > limit
            chunks << buffer
            buffer = +''
            # 1行だけで上限を超える場合は文字数で区切る
            while line.length > limit
              chunks << line[0, limit]
              line = line[limit..]
            end
          end
          buffer << line
        end
        chunks << buffer
        chunks.map(&:rstrip).reject(&:empty?)
      end

      def collect_urls(block, urls)
        case block.type
        when :web_search_tool_result
          return unless block.content.is_a?(Array)
          block.content.each { |result| urls << result.url }
        when :web_fetch_tool_result
          return unless block.content.respond_to?(:url)
          urls << block.content.url
        end
      end

      def send_urls_message(urls)
        text = urls.uniq.map { |url| "<#{url}>" }.join("\n")
        split_message(text).each { |chunk| message.reply(chunk) }
      end

      def collect_codes(block, codes)
        return unless block.type == :server_tool_use && block.name.to_s == 'bash_code_execution'
        codes << block.input[:command]
      end

      def send_code_message(codes)
        return if codes.empty?

        codes.each do |code|
          split_message(code, DISCORD_MAX_LENGTH - "```bash\n\n```".length).each do |chunk|
            message.reply("```bash\n#{chunk}\n```")
          end
        end
      end

      def serialize_content(content)
        content.map do |block|
          case block.type
          when :text
            { type: 'text', text: block.text }
          when :tool_use
            { type: 'tool_use', id: block.id, name: block.name, input: block.input }
          when :mcp_tool_use
            { type: 'mcp_tool_use', id: block.id, name: block.name, server_name: block.server_name, input: block.input }
          when :mcp_tool_result
            { type: 'mcp_tool_result', tool_use_id: block.tool_use_id, is_error: block.is_error, content: block.content.map(&:to_h) }
          when :server_tool_use
            { type: 'server_tool_use', id: block.id, name: block.name.to_s, input: block.input }
          when :web_search_tool_result
            { type: 'web_search_tool_result', tool_use_id: block.tool_use_id, content: serialize_server_tool_content(block.content) }
          when :web_fetch_tool_result
            { type: 'web_fetch_tool_result', tool_use_id: block.tool_use_id, content: serialize_server_tool_content(block.content) }
          when :bash_code_execution_tool_result
            { type: 'bash_code_execution_tool_result', tool_use_id: block.tool_use_id, content: serialize_server_tool_content(block.content) }
          else
            warn "serialize_content: unknown block type: #{block.type.inspect}"
            nil
          end
        end.compact
      end

      def serialize_server_tool_content(content)
        if content.is_a?(Array)
          content.map(&:to_h)
        else
          content.to_h
        end
      end

      def process_tool_use(tool_use)
        input = tool_use.input
        input = input.transform_keys(&:to_s) if input.is_a?(Hash)

        result =
          case tool_use.name.to_s
          when 'memory'
            memory_handler.execute(input, scope_dir: memory_scope_dir)
          when 'set_reminder'
            reminder_handler.execute(input.merge(
              'channel_id' => message.original[:from],
              'user_id' => message.original[:author_id]
            ))
          else
            "Error: Unknown tool #{tool_use.name}"
          end

        {
          type: 'tool_result',
          tool_use_id: tool_use.id,
          content: result
        }
      end

      def client
        @client ||= Anthropic::Client.new
      end

      def memory_handler
        @memory_handler ||= ToolHandlers::Memories.new
      end

      def reminder_handler
        @reminder_handler ||= ToolHandlers::Reminder.new
      end

      def memory_scope_dir
        server_id = message.original[:server_id]
        if server_id
          server_id.to_s
        else
          "dm/#{message.original[:author_id]}"
        end
      end
    end
  end
end

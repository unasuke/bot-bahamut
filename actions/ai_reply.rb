require 'anthropic'
require_relative '../lib/ruboty/patches/discord_typing' unless ENV['LOCAL']
require_relative '../lib/tool_handlers/memories'

module Ruboty
  module Actions
    class AiReply < Base
      MODEL = ENV.fetch('ANTHROPIC_MODEL', 'claude-sonnet-4-6')
      MAX_TOKENS = 1024
      DISCORD_MAX_LENGTH = 2000
      MAX_TOOL_CALLS = 10
      SYSTEM_PROMPT = <<~PROMPT
        あなたは友人同士が集まっているDiscordサーバーにいるbotです。
        日本語で、敬語で回答してください。絵文字はあまり使用しないでください。
        友人同士のカジュアルな会話環境であるため、定型的な敬語表現や定番の挨拶句は避け、敬語を保ちながらも直接的で自然な応答をしてください。
        'bahamut' はあなたの名前ですが、そこに意味はありません。回答する内容とbahamutという単語の意味は関連付ける必要はありません。
        あなた自身のソースコードは https://github.com/unasuke/bot-bahamut にて管理されています。
      PROMPT

      def call(body)
        typing_thread = start_typing_loop

        user_content = "#{message.from_name || 'anonymous'}: #{body}"
        messages = [{ role: 'user', content: user_content }]

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
        any_text_sent = false

        MAX_TOOL_CALLS.times do
          response = client.beta.messages.create(
            model: MODEL,
            max_tokens: MAX_TOKENS,
            system: SYSTEM_PROMPT,
            tools: [
              { type: 'web_search_20260209', name: 'web_search', max_uses: 5 },
              { type: 'web_fetch_20260209', name: 'web_fetch', max_uses: 5 },
              { type: 'memory_20250818', name: 'memory' }
            ],
            messages: messages,
            betas: ["code-execution-web-tools-2026-02-09"]
          )

          pp response

          # Send text blocks immediately and collect URLs
          texts_this_response = []
          response.content.each do |block|
            texts_this_response << block.text if block.type == :text && !block.text.empty?
            collect_urls(block, collected_urls)
          end

          unless texts_this_response.empty?
            reply_text = texts_this_response.join("\n")[0, DISCORD_MAX_LENGTH]
            message.reply(reply_text)
            any_text_sent = true
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
            send_urls_message(collected_urls)
            return
          end
        end

        # Fallback if loop limit reached
        send_urls_message(collected_urls)
        message.reply('すみません、処理が複雑になりすぎました。もう一度お試しください。') unless any_text_sent
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

      MAX_DISPLAY_URLS = 3

      def send_urls_message(urls)
        unique_urls = urls.uniq
        return if unique_urls.empty?

        displayed = unique_urls.first(MAX_DISPLAY_URLS)
        remaining = unique_urls.size - displayed.size
        url_text = displayed.join("\n")
        url_text += "\n他#{remaining}件のURL" if remaining > 0
        message.reply(url_text[0, DISCORD_MAX_LENGTH])
      end

      def serialize_content(content)
        content.map do |block|
          case block.type
          when :text
            { type: 'text', text: block.text }
          when :tool_use
            { type: 'tool_use', id: block.id, name: block.name, input: block.input }
          when :server_tool_use
            { type: 'server_tool_use', id: block.id, name: block.name.to_s, input: block.input }
          when :web_search_tool_result
            { type: 'web_search_tool_result', tool_use_id: block.tool_use_id, content: serialize_server_tool_content(block.content) }
          when :web_fetch_tool_result
            { type: 'web_fetch_tool_result', tool_use_id: block.tool_use_id, content: serialize_server_tool_content(block.content) }
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
        result = memory_handler.execute(input)
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
    end
  end
end

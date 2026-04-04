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
      PROMPT

      def call(body)
        typing_thread = start_typing_loop

        user_content = "#{message.from_name || 'anonymous'}: #{body}"
        messages = [{ role: 'user', content: user_content }]

        reply_text = run_agentic_loop(messages)
        reply_text = reply_text[0, DISCORD_MAX_LENGTH]
        message.reply(reply_text) unless reply_text.empty?
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
        collected_texts = []

        MAX_TOOL_CALLS.times do
          response = client.beta.messages.create(
            model: MODEL,
            max_tokens: MAX_TOKENS,
            system: SYSTEM_PROMPT,
            tools: [
              { type: 'web_search_20260209', name: 'web_search', max_uses: 5 },
              { type: 'memory_20250818', name: 'memory' }
            ],
            messages: messages,
            betas: ["code-execution-web-tools-2026-02-09"]
          )

          pp response

          # Collect text blocks from every response
          response.content.each do |block|
            collected_texts << block.text if block.type == :text && !block.text.empty?
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
            return collected_texts.join("\n")
          end
        end

        # Fallback if loop limit reached
        collected_texts.join("\n").then { |t| t.empty? ? 'すみません、処理が複雑になりすぎました。もう一度お試しください。' : t }
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
            { type: 'web_search_tool_result', tool_use_id: block.tool_use_id, content: serialize_web_search_content(block.content) }
          end
        end.compact
      end

      def serialize_web_search_content(content)
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

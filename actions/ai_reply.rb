require 'anthropic'
require_relative '../lib/ruboty/patches/discord_typing' unless ENV['LOCAL']
require_relative '../lib/tool_handlers/memories'

module Ruboty
  module Actions
    class AiReply < Base
      MODEL = ENV.fetch('ANTHROPIC_MODEL', 'claude-sonnet-4-5')
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
        unless ENV['LOCAL']
          discord_bot = message.robot.adapter.bot
          discord_bot.channel(message.original[:to]).start_typing
        end

        user_content = "#{message.from_name || 'anonymous'}: #{body}"
        messages = [{ role: 'user', content: user_content }]

        reply_text = run_agentic_loop(messages)
        message.reply(reply_text[0, DISCORD_MAX_LENGTH])
      rescue Anthropic::Errors::APIError => e
        message.reply("API error: #{e.message}")
      end

      private

      def run_agentic_loop(messages)
        MAX_TOOL_CALLS.times do
          response = client.messages.create(
            model: MODEL,
            max_tokens: MAX_TOKENS,
            system: SYSTEM_PROMPT,
            tools: [{ type: 'memory_20250818', name: 'memory' }],
            messages: messages
          )

          pp response
          if response.stop_reason == :tool_use
            # Append assistant response with only API-accepted fields
            messages << { role: 'assistant', content: serialize_content(response.content) }

            # Process each tool use block
            tool_results = response.content
              .select { |block| block.type == :tool_use }
              .map { |tool_use| process_tool_use(tool_use) }

            messages << { role: 'user', content: tool_results }
          else
            # Extract final text response
            text_block = response.content.find { |block| block.type == :text }
            return text_block&.text || ''
          end
        end

        # Fallback if loop limit reached
        'すみません、処理が複雑になりすぎました。もう一度お試しください。'
      end

      def serialize_content(content)
        content.map do |block|
          case block.type
          when :text
            { type: 'text', text: block.text }
          when :tool_use
            { type: 'tool_use', id: block.id, name: block.name, input: block.input }
          end
        end.compact
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

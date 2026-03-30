require 'anthropic'

module Ruboty
  module Actions
    class AiReply < Base
      MODEL = ENV.fetch('ANTHROPIC_MODEL', 'claude-sonnet-4-20250514')
      MAX_TOKENS = 1024
      DISCORD_MAX_LENGTH = 2000

      def call(body)
        response = client.messages.create(
          model: MODEL,
          max_tokens: MAX_TOKENS,
          messages: [{ role: 'user', content: body }]
        )
        reply_text = response.content.first.text
        message.reply(reply_text[0, DISCORD_MAX_LENGTH])
      rescue Anthropic::Errors::APIError => e
        message.reply("API error: #{e.message}")
      end

      private

      def client
        @client ||= Anthropic::Client.new
      end
    end
  end
end

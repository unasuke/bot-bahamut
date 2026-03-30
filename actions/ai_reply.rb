require 'anthropic'

module Ruboty
  module Actions
    class AiReply < Base
      MODEL = ENV.fetch('ANTHROPIC_MODEL', 'claude-sonnet-4-5')
      MAX_TOKENS = 1024
      DISCORD_MAX_LENGTH = 2000
      SYSTEM_PROMPT = <<~PROMPT
        あなたは友人同士が集まっているDiscordサーバーにいるbotです。
        日本語で、敬語で回答してください。絵文字はあまり使用しないでください。
        友人同士のカジュアルな会話環境であるため、定型的な敬語表現や定番の挨拶句は避け、敬語を保ちながらも直接的で自然な応答をしてください。
        'bahamut' はあなたの名前ですが、そこに意味はありません。回答する内容とbahamutという単語の意味は関連付ける必要はありません。
      PROMPT

      def call(body)
        response = client.messages.create(
          model: MODEL,
          max_tokens: MAX_TOKENS,
          system: SYSTEM_PROMPT,
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

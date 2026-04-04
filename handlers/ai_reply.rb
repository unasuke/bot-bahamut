module Ruboty
  module Handlers
    class AiReply < Base
      COMMAND_PATTERNS = [
        /model\z/
      ]

      on(/.+/m, name: 'ai_reply', description: 'メンションされた発言にClaude AIで返答する')

      def ai_reply(message)
        return if COMMAND_PATTERNS.any? { |pattern| message.body.match?(pattern) }

        Ruboty::Actions::AiReply.new(message).call(message.body)
      end
    end
  end
end

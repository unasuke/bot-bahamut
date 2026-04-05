module Ruboty
  module Handlers
    class AiReply < Base
      on(/.+/m, name: 'ai_reply', description: 'メンションされた発言にClaude AIで返答する')

      def ai_reply(message)
        Ruboty::Actions::AiReply.new(message).call(message.body)
      end
    end
  end
end

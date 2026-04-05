module Ruboty
  module Handlers
    class Model < Base
      on(/model\z/m, name: 'model', description: '使用中のAIモデルを返す')

      def model(message)
        message.reply(ENV.fetch('ANTHROPIC_MODEL', 'claude-haiku-4-5'))
      end
    end
  end
end

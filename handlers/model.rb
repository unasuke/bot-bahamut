module Ruboty
  module Handlers
    class Model < Base
      on(/model\z/m, name: 'model', description: '使用中のAIモデルを返す')

      def model(message)
        message.reply(ENV['ANTHROPIC_MODEL'] || '(ANTHROPIC_MODEL is not set)')
      end
    end
  end
end

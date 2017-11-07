module Ruboty
  module Handlers
    class ManaCount < Base
      on /10マナ/, name: :handler, description: '10マナ発見機'

      def handler(message)
        message.reply('燃やしてやる')
      end
    end
  end
end

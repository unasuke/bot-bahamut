module Ruboty
  module Handlers
    class ManaCount < Base
      on /眠い/, name: :sleepy, description: '眠い時のバハすけ', all: true

      def sleepy(message)
        message.reply('寝てくれ')
      end
    end
  end
end

# マッチしたactionがあれば即座にreturnし、後続のaction/handlerを実行しないようにする
module Ruboty
  module Handlers
    class Base
      def call(message, options = {})
        self.class.actions.each do |action|
          return true if action.call(self, message, options)
        end
        false
      end
    end
  end

  class Robot
    def receive(attributes)
      message = Message.new(attributes.merge(robot: self))
      matched = handlers.any? { |handler| handler.call(message) }
      unless matched
        handlers.each do |handler|
          handler.call(message, missing: true)
        end
      end
    end
  end
end

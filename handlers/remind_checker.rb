require 'ruboty'
require_relative '../lib/db'

module Ruboty
  module Handlers
    class RemindChecker < Base
      def initialize(robot)
        super
        Thread.new { check_loop }
      end

      def check_loop
        loop do
          now = Time.now.to_i * 1000

          DB.execute(
            "SELECT id, user_id, channel_id, text
             FROM reminders
             WHERE status='pending' AND remind_at <= ?",
            now
          ) do |row|
            id, user_id, channel_id, text = row

            robot.send_message(
              channel: channel_id,
              message: "🔔 <@#{user_id}> #{text}"
            )

            DB.execute(
              "UPDATE reminders SET status='done', completed_at=? WHERE id=?",
              now, id
            )
          end

          sleep 5
        end
      end
    end
  end
end

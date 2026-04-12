require 'ruboty'
require_relative '../lib/db'

module Ruboty
  module Handlers
    class Remind < Base
      on(/remind (\d+) (秒|分|時間) (.+)/, name: 'remind')

      def remind(message)
        value, unit, text = message.match_data.captures

        delay =
          case unit
          when "秒" then value.to_i * 1000
          when "分" then value.to_i * 60 * 1000
          when "時間" then value.to_i * 60 * 60 * 1000
          end

        remind_at = (Time.now.to_i * 1000) + delay

        DB.execute(
          "INSERT INTO reminders (user_id, channel_id, text, remind_at, status)
           VALUES (?, ?, ?, ?, 'pending')",
          [message.original[:author_id], message.to, text, remind_at]
        )

        message.reply("⏰ 登録しました！")
      end
    end
  end
end

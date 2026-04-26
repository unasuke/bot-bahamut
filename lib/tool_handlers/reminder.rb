require_relative '../db'

module ToolHandlers
  class Reminder
    def execute(input)
      delay_sec = (input['hours'].to_i * 3600) +
                  (input['minutes'].to_i * 60) +
                  input['seconds'].to_i
      remind_at_ms = (Time.now.to_i + delay_sec) * 1000
      text = input['text']
      channel_id = input['channel_id']
      user_id = input['user_id']

      DB.execute(
        "INSERT INTO reminders (user_id, channel_id, text, remind_at, status)
         VALUES (?, ?, ?, ?, 'pending')",
        [user_id, channel_id, text, remind_at_ms]
      )

      "リマインダーを登録しました。"
    end
  end
end

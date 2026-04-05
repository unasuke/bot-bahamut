# ruboty-discordアダプタのon_messageをオーバーライドし、
# message.author.name (username) の代わりに
# message.author.display_name (nickname || global_name || username) を使う
module Ruboty
  module Adapters
    class Discord
      private

      def on_message(message)
        robot.receive(
          body: parse_content(message),
          from: message.channel.id,
          from_name: message.author.display_name,
          to: message.channel.id,
          time: message.timestamp
        )
      end
    end
  end
end

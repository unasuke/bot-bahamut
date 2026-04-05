# ruboty-discordアダプタのon_messageをオーバーライドし、
# - message.author.name (username) の代わりに display_name を使う
# - author_id にDiscordユーザーIDを渡す
module Ruboty
  module Adapters
    class Discord
      private

      def on_message(message)
        robot.receive(
          body: parse_content(message),
          from: message.channel.id,
          from_name: message.author.display_name,
          author_id: message.author.id,
          server_id: message.channel.server&.id,
          to: message.channel.id,
          time: message.timestamp
        )
      end
    end
  end
end

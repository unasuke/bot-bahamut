require 'ruboty/discord' unless ENV['LOCAL']
require_relative 'lib/ruboty/patches/discord_display_name' unless ENV['LOCAL']
require_relative 'lib/ruboty/patches/short_circuit_handler'
require './handlers/model'
require_relative 'handlers/remind'
require_relative 'handlers/remind_checker'
require './handlers/ai_reply'
require './actions/ai_reply'

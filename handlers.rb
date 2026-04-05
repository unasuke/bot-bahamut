require 'ruboty/discord' unless ENV['LOCAL']
require_relative 'lib/ruboty/patches/short_circuit_handler'
require './handlers/model'
require './handlers/ai_reply'
require './actions/ai_reply'
require_relative 'handlers/remind'
require_relative 'handlers/remind_checker'

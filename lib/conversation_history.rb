require 'json'
require 'fileutils'

class ConversationHistory
  DEFAULT_DIR = '/var/bot-bahamut/history'
  MAX_MESSAGES = 10
  EXPIRY_SECONDS = 3600

  def initialize(channel_id)
    @dir = ENV.fetch('HISTORY_DIR', DEFAULT_DIR)
    @path = File.join(@dir, "#{channel_id}.json")
    FileUtils.mkdir_p(@dir)
  end

  def load
    return [] unless File.exist?(@path)

    cutoff = Time.now.to_i - EXPIRY_SECONDS
    load_raw
      .select { |e| e[:timestamp] >= cutoff }
      .last(MAX_MESSAGES)
      .map { |e| e[:message] }
  rescue JSON::ParserError
    []
  end

  def save(messages)
    now = Time.now.to_i
    cutoff = now - EXPIRY_SECONDS

    existing = load_raw.select { |e| e[:timestamp] >= cutoff }
    new_entries = messages.map { |m| { timestamp: now, message: m } }

    merged = (existing + new_entries).last(MAX_MESSAGES * 2)
    File.write(@path, JSON.generate(merged))
  end

  private

  def load_raw
    return [] unless File.exist?(@path)
    JSON.parse(File.read(@path), symbolize_names: true)
  rescue JSON::ParserError
    []
  end
end

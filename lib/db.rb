require 'sqlite3'

DB = SQLite3::Database.new(ENV.fetch('REMINDERS_DB_PATH', '/var/bot-bahamut/reminders.db'))

DB.execute <<-SQL
CREATE TABLE IF NOT EXISTS reminders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT,
  channel_id TEXT,
  text TEXT,
  remind_at INTEGER,
  status TEXT,
  completed_at INTEGER
)
SQL

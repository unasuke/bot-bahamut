require 'discordrb'
require 'sqlite3'

TOKEN = ENV["DISCORD_TOKEN"]

bot = Discordrb::Bot.new token: TOKEN
db = SQLite3::Database.new "todo.db"

db.execute <<-SQL
CREATE TABLE IF NOT EXISTS public_lists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  guild_id TEXT,
  title TEXT
);
SQL


db.execute <<-SQL
CREATE TABLE IF NOT EXISTS public_tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  list_id INTEGER,
  title TEXT,
  done INTEGER DEFAULT 0
);
SQL

db.execute <<-SQL
CREATE TABLE IF NOT EXISTS private_lists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  guild_id TEXT,
  user_id TEXT,
  title TEXT
);
SQL

db.execute <<-SQL
CREATE TABLE IF NOT EXISTS private_tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  list_id INTEGER,
  title TEXT,
  done INTEGER DEFAULT 0
);
SQL

def reindex(db, table, list_id)
  tasks = db.execute("SELECT id FROM #{table} WHERE list_id=? ORDER BY id ASC", list_id)
  tasks.each_with_index do |t, i|
    db.execute("UPDATE #{table} SET id=? WHERE id=?", [i + 1, t[0]])
  end
end

def calc(db, table, list_id)
  tasks = db.execute("SELECT done FROM #{table} WHERE list_id=?", list_id)
  total = tasks.size
  done = tasks.count { |t| t[0] == 1 }
  percent = total == 0 ? 0 : ((done.to_f / total) * 100).ceil
  [done, total, percent]
end

def render(db, list_table, task_table, list_id)
  title = db.execute("SELECT title FROM #{list_table} WHERE id=?", list_id).flatten.first
  return nil unless title

  done, total, percent = calc(db, task_table, list_id)

  tasks = db.execute("SELECT id, title, done FROM #{task_table} WHERE list_id=? ORDER BY id ASC", list_id)

  out = ""
  out << "#{title}（#{done}/#{total} #{percent}%）\n"
  out << "──────────────────\n"

  tasks.each do |t|
    mark = t[2] == 1 ? "☑" : "☐"
    out << "#{mark}#{t[0]}. #{t[1]}\n"
  end

  out << "──────────────────"
  out
end

bot.message(with_text: /^todo /) do |event|
  args = event.message.content.split(" ")
  cmd = args[1]

  guild = event.server&.id.to_s
  user = event.user.id.to_s

  if cmd == "listadd"
    title = args[2..].join(" ")
    db.execute("INSERT INTO public_lists (guild_id,title) VALUES (?,?)", [guild, title])
    id = db.last_insert_row_id
    event.respond "パブリックリストを作成しました　#{id}.#{title}"
  end

  if cmd == "listremove"
    id = args[2].to_i
    return event.respond "該当パブリックリストがありません" if db.execute("SELECT id FROM public_lists WHERE id=?", id).empty?

    db.execute("DELETE FROM public_tasks WHERE list_id=?", id)
    db.execute("DELETE FROM public_lists WHERE id=?", id)
    event.respond "パブリックリストを削除しました"
  end

  if cmd == "listdisplay"
    if args[2] == "all"
      lists = db.execute("SELECT id FROM public_lists ORDER BY id ASC")
      return event.respond "パブリックリストがありません" if lists.empty?
      event.respond lists.map { |l| render(db, "public_lists", "public_tasks", l[0]) }.join("\n\n")
    else
      id = args[2].to_i
      out = render(db, "public_lists", "public_tasks", id)
      return event.respond "該当パブリックリストがありません" unless out
      event.respond out
    end
  end

  if cmd == "listedit"
    id = args[2].to_i
    title = args[3..].join(" ")
    db.execute("UPDATE public_lists SET title=? WHERE id=?", [title, id])
    event.respond "上書きしました　#{id}.#{title}"
  end

  if cmd == "taskadd"
    list_id = args[2].to_i
    title = args[3..].join(" ")

    return event.respond "該当パブリックリストがありません" if db.execute("SELECT id FROM public_lists WHERE id=?", list_id).empty?

    db.execute("INSERT INTO public_tasks (list_id,title,done) VALUES (?,?,0)", [list_id, title])
    reindex(db, "public_tasks", list_id)

    event.respond render(db, "public_lists", "public_tasks", list_id)
  end

  if cmd == "taskremove"
    list_id = args[2].to_i
    return event.respond "該当パブリックリストがありません" if db.execute("SELECT id FROM public_lists WHERE id=?", list_id).empty?

    if args[3] == "all"
      db.execute("DELETE FROM public_tasks WHERE list_id=?", list_id)
    else
      no = args[3].to_i
      task = db.execute("SELECT id FROM public_tasks WHERE list_id=? ORDER BY id ASC", list_id)[no - 1]
      return event.respond "タスクがありません" unless task
      db.execute("DELETE FROM public_tasks WHERE id=?", task[0])
    end

    reindex(db, "public_tasks", list_id)
    event.respond render(db, "public_lists", "public_tasks", list_id)
  end

  if cmd == "taskdone"
    list_id = args[2].to_i
    return event.respond "該当パブリックリストがありません" if db.execute("SELECT id FROM public_lists WHERE id=?", list_id).empty?

    no = args[3].to_i
    task = db.execute("SELECT id,done FROM public_tasks WHERE list_id=? ORDER BY id ASC", list_id)[no - 1]
    return event.respond "タスクがありません" unless task
    return event.respond "既に完了しています" if task[1] == 1

    db.execute("UPDATE public_tasks SET done=1 WHERE id=?", task[0])
    event.respond render(db, "public_lists", "public_tasks", list_id)
  end

  if cmd == "taskcancel"
    list_id = args[2].to_i
    no = args[3].to_i
    task = db.execute("SELECT id,done FROM public_tasks WHERE list_id=? ORDER BY id ASC", list_id)[no - 1]
    return event.respond "タスクがありません" unless task
    return event.respond "未完了です" if task[1] == 0

    db.execute("UPDATE public_tasks SET done=0 WHERE id=?", task[0])
    event.respond render(db, "public_lists", "public_tasks", list_id)
  end

  if cmd == "taskedit"
    list_id = args[2].to_i
    no = args[3].to_i
    title = args[4..].join(" ")

    task = db.execute("SELECT id FROM public_tasks WHERE list_id=? ORDER BY id ASC", list_id)[no - 1]
    return event.respond "タスクがありません" unless task

    db.execute("UPDATE public_tasks SET title=? WHERE id=?", [title, task[0]])
    event.respond render(db, "public_lists", "public_tasks", list_id)
  end
end

bot.run
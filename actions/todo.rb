# frozen_string_literal: true

require 'sqlite3'

module Ruboty
  module Actions
    class Todo
      DB_PATH = ENV.fetch('TODO_DB_PATH', './todo.db')

      def initialize
        @db = SQLite3::Database.new(DB_PATH)
        @db.results_as_hash = true
        setup_tables
      end

      # ─────────────────────────────────────────
      # DB セットアップ
      # ─────────────────────────────────────────
      def setup_tables
        @db.execute_batch <<~SQL
          CREATE TABLE IF NOT EXISTS public_lists (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id TEXT    NOT NULL,
            number    INTEGER NOT NULL,
            title     TEXT    NOT NULL
          );
          CREATE TABLE IF NOT EXISTS public_tasks (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            list_id   INTEGER NOT NULL REFERENCES public_lists(id),
            number    INTEGER NOT NULL,
            title     TEXT    NOT NULL,
            done      INTEGER NOT NULL DEFAULT 0
          );
          CREATE TABLE IF NOT EXISTS private_lists (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT    NOT NULL,
            number  INTEGER NOT NULL,
            title   TEXT    NOT NULL
          );
          CREATE TABLE IF NOT EXISTS private_tasks (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            list_id INTEGER NOT NULL REFERENCES private_lists(id),
            number  INTEGER NOT NULL,
            title   TEXT    NOT NULL,
            done    INTEGER NOT NULL DEFAULT 0
          );
        SQL
      end

      # ─────────────────────────────────────────
      # ヘルパー
      # ─────────────────────────────────────────
      def next_list_number(table, scope_col, scope_val)
        row = @db.get_first_row("SELECT COALESCE(MAX(number),0)+1 AS n FROM #{table} WHERE #{scope_col}=?", scope_val)
        row['n']
      end

      def next_task_number(task_table, list_id)
        row = @db.get_first_row("SELECT COALESCE(MAX(number),0)+1 AS n FROM #{task_table} WHERE list_id=?", list_id)
        row['n']
      end

      def renumber_lists(table, scope_col, scope_val)
        rows = @db.execute("SELECT id FROM #{table} WHERE #{scope_col}=? ORDER BY number ASC", scope_val)
        rows.each_with_index { |r, i| @db.execute("UPDATE #{table} SET number=? WHERE id=?", i + 1, r['id']) }
      end

      def renumber_tasks(task_table, list_id)
        rows = @db.execute("SELECT id FROM #{task_table} WHERE list_id=? ORDER BY number ASC", list_id)
        rows.each_with_index { |r, i| @db.execute("UPDATE #{task_table} SET number=? WHERE id=?", i + 1, r['id']) }
      end

      # ─────────────────────────────────────────
      # 表示フォーマット
      # ─────────────────────────────────────────
      def format_list(list, tasks)
        total   = tasks.size
        done_ct = tasks.count { |t| t['done'] == 1 }
        pct     = total.zero? ? 0 : (done_ct.to_f / total * 100).round

        lines = []
        lines << "#{list['number']}:#{list['title']}"
        lines << "（#{done_ct}/#{total}　#{pct}%）"
        lines << '──────────────────'
        if tasks.empty?
          lines << '（タスクがありません）'
        else
          tasks.each do |t|
            mark = t['done'] == 1 ? '☑' : '☐'
            lines << "#{mark}#{t['number']}. #{t['title']}"
          end
        end
        lines << '──────────────────'
        lines.join("\n")
      end

      def tasks_for_list(task_table, list_id)
        @db.execute("SELECT * FROM #{task_table} WHERE list_id=? ORDER BY number ASC", list_id)
      end

      # ─────────────────────────────────────────
      # パブリックリスト操作
      # ─────────────────────────────────────────
      def public_list_add(server_id, title)
        num = next_list_number('public_lists', 'server_id', server_id)
        @db.execute('INSERT INTO public_lists (server_id,number,title) VALUES (?,?,?)', server_id, num, title)
        "パブリックリストを作成しました　#{num}.#{title}"
      end

      def public_list_remove(server_id, number)
        list = @db.get_first_row('SELECT * FROM public_lists WHERE server_id=? AND number=?', server_id, number)
        return '該当パブリックリストがありません' unless list

        @db.execute('DELETE FROM public_tasks WHERE list_id=?', list['id'])
        @db.execute('DELETE FROM public_lists WHERE id=?', list['id'])
        renumber_lists('public_lists', 'server_id', server_id)
        'パブリックリストを削除しました'
      end

      def public_list_display(server_id, number)
        list = @db.get_first_row('SELECT * FROM public_lists WHERE server_id=? AND number=?', server_id, number)
        return '該当パブリックリストがありません' unless list

        tasks = tasks_for_list('public_tasks', list['id'])
        format_list(list, tasks)
      end

      def public_list_display_all(server_id)
        lists = @db.execute('SELECT * FROM public_lists WHERE server_id=? ORDER BY number ASC', server_id)
        return 'パブリックリストがありません' if lists.empty?

        lists.map { |l| format_list(l, tasks_for_list('public_tasks', l['id'])) }.join("\n\n")
      end

      def public_list_edit(server_id, number, new_title)
        list = @db.get_first_row('SELECT * FROM public_lists WHERE server_id=? AND number=?', server_id, number)
        return '該当パブリックリストがありません' unless list

        @db.execute('UPDATE public_lists SET title=? WHERE id=?', new_title, list['id'])
        "上書きしました　#{number}.#{new_title}"
      end

      # ─────────────────────────────────────────
      # プライベートリスト操作
      # ─────────────────────────────────────────
      def private_list_add(user_id, title)
        num = next_list_number('private_lists', 'user_id', user_id)
        @db.execute('INSERT INTO private_lists (user_id,number,title) VALUES (?,?,?)', user_id, num, title)
        "プライベートリストを作成しました　#{num}.#{title}"
      end

      def private_list_remove(user_id, number)
        list = @db.get_first_row('SELECT * FROM private_lists WHERE user_id=? AND number=?', user_id, number)
        return '該当プライベートリストがありません' unless list

        @db.execute('DELETE FROM private_tasks WHERE list_id=?', list['id'])
        @db.execute('DELETE FROM private_lists WHERE id=?', list['id'])
        renumber_lists('private_lists', 'user_id', user_id)
        'プライベートリストを削除しました'
      end

      def private_list_display(user_id, number)
        list = @db.get_first_row('SELECT * FROM private_lists WHERE user_id=? AND number=?', user_id, number)
        return '該当プライベートリストがありません' unless list

        tasks = tasks_for_list('private_tasks', list['id'])
        format_list(list, tasks)
      end

      def private_list_display_all(user_id)
        lists = @db.execute('SELECT * FROM private_lists WHERE user_id=? ORDER BY number ASC', user_id)
        return 'プライベートリストがありません' if lists.empty?

        lists.map { |l| format_list(l, tasks_for_list('private_tasks', l['id'])) }.join("\n\n")
      end

      def private_list_edit(user_id, number, new_title)
        list = @db.get_first_row('SELECT * FROM private_lists WHERE user_id=? AND number=?', user_id, number)
        return '該当プライベートリストがありません' unless list

        @db.execute('UPDATE private_lists SET title=? WHERE id=?', new_title, list['id'])
        "上書きしました　#{number}.#{new_title}"
      end

      # ─────────────────────────────────────────
      # パブリックタスク操作
      # ─────────────────────────────────────────
      def public_task_add(server_id, list_num, title)
        list = @db.get_first_row('SELECT * FROM public_lists WHERE server_id=? AND number=?', server_id, list_num)
        return [nil, '該当パブリックリストがありません'] unless list

        num = next_task_number('public_tasks', list['id'])
        @db.execute('INSERT INTO public_tasks (list_id,number,title,done) VALUES (?,?,?,0)', list['id'], num, title)
        ['タスクを作成しました', list['id']]
      end

      def public_task_remove(server_id, list_num, task_num_or_all)
        list = @db.get_first_row('SELECT * FROM public_lists WHERE server_id=? AND number=?', server_id, list_num)
        return [nil, '該当パブリックリストがありません'] unless list

        if task_num_or_all == 'all'
          @db.execute('DELETE FROM public_tasks WHERE list_id=?', list['id'])
          [list['id'], 'リスト内のタスクを全て削除しました']
        else
          task = @db.get_first_row('SELECT * FROM public_tasks WHERE list_id=? AND number=?', list['id'], task_num_or_all)
          return [list['id'], 'タスクがありません'] unless task

          @db.execute('DELETE FROM public_tasks WHERE id=?', task['id'])
          renumber_tasks('public_tasks', list['id'])
          [list['id'], 'タスクを削除しました']
        end
      end

      def public_task_done(server_id, list_num, task_num_or_all)
        list = @db.get_first_row('SELECT * FROM public_lists WHERE server_id=? AND number=?', server_id, list_num)
        return [nil, '該当パブリックリストがありません'] unless list

        if task_num_or_all == 'all'
          total = @db.get_first_row('SELECT COUNT(*) AS n FROM public_tasks WHERE list_id=?', list['id'])['n']
          return [list['id'], 'タスクがありません。'] if total == 0

          done_count = @db.get_first_row('SELECT COUNT(*) AS n FROM public_tasks WHERE list_id=? AND done=1', list['id'])['n']
          return [list['id'], '全てのタスクが既に完了しています'] if done_count == total

          @db.execute('UPDATE public_tasks SET done=1 WHERE list_id=?', list['id'])
          ["#{list_num}のパブリックリスト内のタスクを全て完了にしました", list['id']]
        else
          task = @db.get_first_row('SELECT * FROM public_tasks WHERE list_id=? AND number=?', list['id'], task_num_or_all)
          return [list['id'], 'タスクがありません'] unless task
          return [list['id'], 'このタスクは既に完了しています'] if task['done'] == 1

          @db.execute('UPDATE public_tasks SET done=1 WHERE id=?', task['id'])
          ['タスクを完了にしました', list['id']]
        end
      end

      def public_task_cancel(server_id, list_num, task_num_or_all)
        list = @db.get_first_row('SELECT * FROM public_lists WHERE server_id=? AND number=?', server_id, list_num)
        return [nil, '該当パブリックリストがありません'] unless list

        if task_num_or_all == 'all'
          count = @db.get_first_row('SELECT COUNT(*) AS n FROM public_tasks WHERE list_id=?', list['id'])['n']
          return [list['id'], 'タスクがありません。'] if count == 0

          done_count = @db.get_first_row('SELECT COUNT(*) AS n FROM public_tasks WHERE list_id=? AND done=1', list['id'])['n']
          return [list['id'], '全てのタスクが完了していません'] if done_count == 0

          @db.execute('UPDATE public_tasks SET done=0 WHERE list_id=? AND done=1', list['id'])
          ["#{list_num}のパブリックリスト内の完了済みタスクの全ての完了を取り消しました", list['id']]
        else
          task = @db.get_first_row('SELECT * FROM public_tasks WHERE list_id=? AND number=?', list['id'], task_num_or_all)
          return [list['id'], 'タスクがありません'] unless task
          return [list['id'], 'このタスクは完了していません'] if task['done'] == 0

          @db.execute('UPDATE public_tasks SET done=0 WHERE id=?', task['id'])
          ['完了を取り消しました', list['id']]
        end
      end

      def public_task_edit(server_id, list_num, task_num, new_title)
        list = @db.get_first_row('SELECT * FROM public_lists WHERE server_id=? AND number=?', server_id, list_num)
        return [nil, '該当パブリックリストがありません'] unless list

        task = @db.get_first_row('SELECT * FROM public_tasks WHERE list_id=? AND number=?', list['id'], task_num)
        return [list['id'], 'タスクがありません'] unless task

        @db.execute('UPDATE public_tasks SET title=? WHERE id=?', new_title, task['id'])
        ['上書きしました', list['id']]
      end

      # ─────────────────────────────────────────
      # プライベートタスク操作
      # ─────────────────────────────────────────
      def private_task_add(user_id, list_num, title)
        list = @db.get_first_row('SELECT * FROM private_lists WHERE user_id=? AND number=?', user_id, list_num)
        return [nil, '該当プライベートリストがありません'] unless list

        num = next_task_number('private_tasks', list['id'])
        @db.execute('INSERT INTO private_tasks (list_id,number,title,done) VALUES (?,?,?,0)', list['id'], num, title)
        ['タスクを作成しました', list['id']]
      end

      def private_task_remove(user_id, list_num, task_num_or_all)
        list = @db.get_first_row('SELECT * FROM private_lists WHERE user_id=? AND number=?', user_id, list_num)
        return [nil, '該当プライベートリストがありません'] unless list

        if task_num_or_all == 'all'
          @db.execute('DELETE FROM private_tasks WHERE list_id=?', list['id'])
          [list['id'], 'リスト内のタスクを全て削除しました']
        else
          task = @db.get_first_row('SELECT * FROM private_tasks WHERE list_id=? AND number=?', list['id'], task_num_or_all)
          return [list['id'], 'タスクがありません'] unless task

          @db.execute('DELETE FROM private_tasks WHERE id=?', task['id'])
          renumber_tasks('private_tasks', list['id'])
          [list['id'], 'タスクを削除しました']
        end
      end

      def private_task_done(user_id, list_num, task_num_or_all)
        list = @db.get_first_row('SELECT * FROM private_lists WHERE user_id=? AND number=?', user_id, list_num)
        return [nil, '該当プライベートリストがありません'] unless list

        if task_num_or_all == 'all'
          total = @db.get_first_row('SELECT COUNT(*) AS n FROM private_tasks WHERE list_id=?', list['id'])['n']
          return [list['id'], 'タスクがありません。'] if total == 0

          done_count = @db.get_first_row('SELECT COUNT(*) AS n FROM private_tasks WHERE list_id=? AND done=1', list['id'])['n']
          return [list['id'], '全てのタスクが既に完了しています'] if done_count == total

          @db.execute('UPDATE private_tasks SET done=1 WHERE list_id=?', list['id'])
          ["#{list_num}のプライベートリスト内のタスクを全て完了にしました", list['id']]
        else
          task = @db.get_first_row('SELECT * FROM private_tasks WHERE list_id=? AND number=?', list['id'], task_num_or_all)
          return [list['id'], 'タスクがありません'] unless task
          return [list['id'], 'このタスクは既に完了しています'] if task['done'] == 1

          @db.execute('UPDATE private_tasks SET done=1 WHERE id=?', task['id'])
          ['タスクを完了にしました', list['id']]
        end
      end

      def private_task_cancel(user_id, list_num, task_num_or_all)
        list = @db.get_first_row('SELECT * FROM private_lists WHERE user_id=? AND number=?', user_id, list_num)
        return [nil, '該当プライベートリストがありません'] unless list

        if task_num_or_all == 'all'
          count = @db.get_first_row('SELECT COUNT(*) AS n FROM private_tasks WHERE list_id=?', list['id'])['n']
          return [list['id'], 'タスクがありません。'] if count == 0

          done_count = @db.get_first_row('SELECT COUNT(*) AS n FROM private_tasks WHERE list_id=? AND done=1', list['id'])['n']
          return [list['id'], '全てのタスクが完了していません'] if done_count == 0

          @db.execute('UPDATE private_tasks SET done=0 WHERE list_id=? AND done=1', list['id'])
          ["#{list_num}のプライベートリスト内の完了済みタスクの全ての完了を取り消しました", list['id']]
        else
          task = @db.get_first_row('SELECT * FROM private_tasks WHERE list_id=? AND number=?', list['id'], task_num_or_all)
          return [list['id'], 'タスクがありません'] unless task
          return [list['id'], 'このタスクは完了していません'] if task['done'] == 0

          @db.execute('UPDATE private_tasks SET done=0 WHERE id=?', task['id'])
          ['完了を取り消しました', list['id']]
        end
      end

      def private_task_edit(user_id, list_num, task_num, new_title)
        list = @db.get_first_row('SELECT * FROM private_lists WHERE user_id=? AND number=?', user_id, list_num)
        return [nil, '該当プライベートリストがありません'] unless list

        task = @db.get_first_row('SELECT * FROM private_tasks WHERE list_id=? AND number=?', list['id'], task_num)
        return [list['id'], 'タスクがありません'] unless task

        @db.execute('UPDATE private_tasks SET title=? WHERE id=?', new_title, task['id'])
        ['上書きしました', list['id']]
      end

      # ─────────────────────────────────────────
      # リスト再取得（タスク操作後の表示用）
      # ─────────────────────────────────────────
      def public_list_display_by_id(list_id)
        list = @db.get_first_row('SELECT * FROM public_lists WHERE id=?', list_id)
        return '' unless list

        tasks = tasks_for_list('public_tasks', list_id)
        format_list(list, tasks)
      end

      def private_list_display_by_id(list_id)
        list = @db.get_first_row('SELECT * FROM private_lists WHERE id=?', list_id)
        return '' unless list

        tasks = tasks_for_list('private_tasks', list_id)
        format_list(list, tasks)
      end
    end
  end
end
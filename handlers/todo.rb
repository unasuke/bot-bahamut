# frozen_string_literal: true

require 'ruboty'
require_relative '../actions/todo'

module Ruboty
  module Handlers
    class Todo < Base
      # ─────────────────────────────────────────
      # ヘルプ
      # ─────────────────────────────────────────
      on(/\Atodo help\z/,
         name: 'todo_help',
         description: 'ToDoコマンド一覧を表示')

      # ─────────────────────────────────────────
      # リスト（パブリック）
      # ─────────────────────────────────────────
      on(/\Atodo listadd (.+)\z/,
         name: 'todo_listadd',
         description: 'パブリックリストを作成')

      on(/\Atodo listremove (\d+)\z/,
         name: 'todo_listremove',
         description: 'パブリックリストを削除')

      on(/\Atodo listdisplay (all|\d+)\z/,
         name: 'todo_listdisplay',
         description: 'パブリックリストを表示')

      on(/\Atodo listedit (\d+) (.+)\z/,
         name: 'todo_listedit',
         description: 'パブリックリストのタイトルを編集')

      # ─────────────────────────────────────────
      # リスト（プライベート）
      # ─────────────────────────────────────────
      on(/\Atodo plistadd (.+)\z/,
         name: 'todo_plistadd',
         description: 'プライベートリストを作成')

      on(/\Atodo plistremove (\d+)\z/,
         name: 'todo_plistremove',
         description: 'プライベートリストを削除')

      on(/\Atodo plistdisplay (all|\d+)\z/,
         name: 'todo_plistdisplay',
         description: 'プライベートリストを表示')

      on(/\Atodo plistedit (\d+) (.+)\z/,
         name: 'todo_plistedit',
         description: 'プライベートリストのタイトルを編集')

      # ─────────────────────────────────────────
      # タスク（パブリック）
      # ─────────────────────────────────────────
      on(/\Atodo taskadd (\d+) (.+)\z/,
         name: 'todo_taskadd',
         description: 'パブリックリストにタスクを追加')

      on(/\Atodo taskremove (\d+) (\d+|all)\z/,
         name: 'todo_taskremove',
         description: 'パブリックタスクを削除')

      on(/\Atodo taskdone (\d+) (\d+|all)\z/,
         name: 'todo_taskdone',
         description: 'パブリックタスクを完了にする')

      on(/\Atodo taskcancel (\d+) (\d+|all)\z/,
         name: 'todo_taskcancel',
         description: 'パブリックタスクの完了を取り消す')

      on(/\Atodo taskedit (\d+) (\d+) (.+)\z/,
         name: 'todo_taskedit',
         description: 'パブリックタスクのタイトルを編集')

      # ─────────────────────────────────────────
      # タスク（プライベート）
      # ─────────────────────────────────────────
      on(/\Atodo ptaskadd (\d+) (.+)\z/,
         name: 'todo_ptaskadd',
         description: 'プライベートリストにタスクを追加')

      on(/\Atodo ptaskremove (\d+) (\d+|all)\z/,
         name: 'todo_ptaskremove',
         description: 'プライベートタスクを削除')

      on(/\Atodo ptaskdone (\d+) (\d+|all)\z/,
         name: 'todo_ptaskdone',
         description: 'プライベートタスクを完了にする')

      on(/\Atodo ptaskcancel (\d+) (\d+|all)\z/,
         name: 'todo_ptaskcancel',
         description: 'プライベートタスクの完了を取り消す')

      on(/\Atodo ptaskedit (\d+) (\d+) (.+)\z/,
         name: 'todo_ptaskedit',
         description: 'プライベートタスクのタイトルを編集')

      # ─────────────────────────────────────────
      # 不一致フォールバック（todo で始まる全コマンド）
      # ─────────────────────────────────────────
      on(/\Atodo .+/,
         name: 'todo_unknown',
         description: '不明なtodoコマンド')

      # ════════════════════════════════════════
      # ハンドラー実装
      # ════════════════════════════════════════

      def todo_help(message)
        message.reply(help_text)
      end

      # ── リスト（パブリック） ──

      def todo_listadd(message)
        title = message.match_data[1]
        result = todo_action.public_list_add(server_id(message), title)
        message.reply(result)
      end

      def todo_listremove(message)
        num = message.match_data[1].to_i
        result = todo_action.public_list_remove(server_id(message), num)
        message.reply(result)
      end

      def todo_listdisplay(message)
        arg = message.match_data[1]
        result = if arg == 'all'
                   todo_action.public_list_display_all(server_id(message))
                 else
                   todo_action.public_list_display(server_id(message), arg.to_i)
                 end
        message.reply(result)
      end

      def todo_listedit(message)
        num       = message.match_data[1].to_i
        new_title = message.match_data[2]
        result = todo_action.public_list_edit(server_id(message), num, new_title)
        message.reply(result)
      end

      # ── リスト（プライベート） ──

      def todo_plistadd(message)
        title = message.match_data[1]
        result = todo_action.private_list_add(user_id(message), title)
        message.reply(result)
      end

      def todo_plistremove(message)
        num = message.match_data[1].to_i
        result = todo_action.private_list_remove(user_id(message), num)
        message.reply(result)
      end

      def todo_plistdisplay(message)
        arg = message.match_data[1]
        result = if arg == 'all'
                   todo_action.private_list_display_all(user_id(message))
                 else
                   todo_action.private_list_display(user_id(message), arg.to_i)
                 end
        message.reply(result)
      end

      def todo_plistedit(message)
        num       = message.match_data[1].to_i
        new_title = message.match_data[2]
        result = todo_action.private_list_edit(user_id(message), num, new_title)
        message.reply(result)
      end

      # ── タスク（パブリック） ──

      def todo_taskadd(message)
        list_num = message.match_data[1].to_i
        title    = message.match_data[2]
        msg, list_id = todo_action.public_task_add(server_id(message), list_num, title)
        reply_with_list_public(message, msg, list_id)
      end

      def todo_taskremove(message)
        list_num = message.match_data[1].to_i
        task_arg = message.match_data[2] == 'all' ? 'all' : message.match_data[2].to_i
        msg, list_id = todo_action.public_task_remove(server_id(message), list_num, task_arg)
        reply_with_list_public(message, msg, list_id)
      end

      def todo_taskdone(message)
        list_num = message.match_data[1].to_i
        task_arg = message.match_data[2] == 'all' ? 'all' : message.match_data[2].to_i
        msg, list_id = todo_action.public_task_done(server_id(message), list_num, task_arg)
        reply_with_list_public(message, msg, list_id)
      end

      def todo_taskcancel(message)
        list_num = message.match_data[1].to_i
        task_arg = message.match_data[2] == 'all' ? 'all' : message.match_data[2].to_i
        msg, list_id = todo_action.public_task_cancel(server_id(message), list_num, task_arg)
        reply_with_list_public(message, msg, list_id)
      end

      def todo_taskedit(message)
        list_num  = message.match_data[1].to_i
        task_num  = message.match_data[2].to_i
        new_title = message.match_data[3]
        msg, list_id = todo_action.public_task_edit(server_id(message), list_num, task_num, new_title)
        reply_with_list_public(message, msg, list_id)
      end

      # ── タスク（プライベート） ──

      def todo_ptaskadd(message)
        list_num = message.match_data[1].to_i
        title    = message.match_data[2]
        msg, list_id = todo_action.private_task_add(user_id(message), list_num, title)
        reply_with_list_private(message, msg, list_id)
      end

      def todo_ptaskremove(message)
        list_num = message.match_data[1].to_i
        task_arg = message.match_data[2] == 'all' ? 'all' : message.match_data[2].to_i
        msg, list_id = todo_action.private_task_remove(user_id(message), list_num, task_arg)
        reply_with_list_private(message, msg, list_id)
      end

      def todo_ptaskdone(message)
        list_num = message.match_data[1].to_i
        task_arg = message.match_data[2] == 'all' ? 'all' : message.match_data[2].to_i
        msg, list_id = todo_action.private_task_done(user_id(message), list_num, task_arg)
        reply_with_list_private(message, msg, list_id)
      end

      def todo_ptaskcancel(message)
        list_num = message.match_data[1].to_i
        task_arg = message.match_data[2] == 'all' ? 'all' : message.match_data[2].to_i
        msg, list_id = todo_action.private_task_cancel(user_id(message), list_num, task_arg)
        reply_with_list_private(message, msg, list_id)
      end

      def todo_ptaskedit(message)
        list_num  = message.match_data[1].to_i
        task_num  = message.match_data[2].to_i
        new_title = message.match_data[3]
        msg, list_id = todo_action.private_task_edit(user_id(message), list_num, task_num, new_title)
        reply_with_list_private(message, msg, list_id)
      end

      # ── 不明コマンド ──

      def todo_unknown(message)
        message.reply('コマンドが見つかりません。')
      end

      private

      # Rubotyの message オブジェクトからサーバーIDとユーザーIDを取得
      # ruboty-discord の場合 channel_id をサーバーIDとして使用
      # （guild_id が取れる場合はそちらを優先）
      def server_id(message)
        message.original[:guild_id] ||
          message.original[:channel_id] ||
          message.original[:room] ||
          'default_server'
      end

      def user_id(message)
        message.original[:from] ||
          message.original[:user_id] ||
          message.from_name
      end

      # タスク操作後の返信：操作結果メッセージ + リスト表示（成功時のみ）
      def reply_with_list_public(message, msg, list_id)
        if list_id
          list_display = todo_action.public_list_display_by_id(list_id)
          message.reply("#{msg}\n\n#{list_display}")
        else
          message.reply(msg)
        end
      end

      def reply_with_list_private(message, msg, list_id)
        if list_id
          list_display = todo_action.private_list_display_by_id(list_id)
          message.reply("#{msg}\n\n#{list_display}")
        else
          message.reply(msg)
        end
      end

      def todo_action
        @todo_action ||= Ruboty::Actions::Todo.new
      end

      def help_text
        <<~HELP
          [リスト（パブリック）]
          todo listadd タイトル名
          ⇒　タイトル名の名前のパブリックリストを作成
          todo listremove x
          ⇒　x番のパブリックリストを削除（中のタスクも全削除）
          todo listdisplay x
          ⇒　x番のパブリックリストのみタスクも含めてを表示
          todo listdisplay all
          ⇒　パブリックリストを各パブリックリストのタスクも含めて全て表示
          todo listedit x 新しいタイトル名　
          ⇒　x番のパブリックリストのタイトル名を新しいタイトル名に上書き

          [リスト（プライベート）]
          todo plistadd タイトル名
          ⇒　タイトル名の名前のプライベートリストを作成
          todo plistremove x
          ⇒　x番のプライベートリストを削除（中のタスクも全削除）
          todo plistdisplay x
          ⇒　x番のプライベートリストのみタスクも含めてを表示
          todo plistdisplay all
          ⇒　プライベートリストを各プライベートリストのタスクも含めて全て表示
          todo plistedit x タイトル名
          ⇒　x番のプライベートリストのタイトル名をタイトル名に上書き

          [タスク（パブリック）]
          todo taskadd x タイトル名
          ⇒　x番のパブリックリストにタイトル名のタイトルのタスクを作成
          todo taskremove x y
          ⇒　x番のパブリックリスト内のy番のタスクを削除
          todo taskremove x all
          ⇒　x番のパブリックリスト内のタスクを全て削除
          todo taskdone x y
          ⇒　x番のパブリックリスト内のy番のタスクを完了にする
          todo taskdone x all
          ⇒　x番のパブリックリスト内のタスクを全て完了にする
          todo taskcancel x y
          ⇒　xと番のパブリックリスト内のy番のタスクの完了を取り消す
          todo taskcancel x all
          ⇒　x番のパブリックリスト内の完了しているタスクの全ての完了を取り消す
          todo taskedit x y 新しいタイトル名
          ⇒　x番のパブリックリスト内のy番のタスクのタイトルを新しいタイトル名に上書き

          [タスク（プライベート）]
          todo ptaskadd x タイトル名
          ⇒　x番のプライベートリストにタイトル名のタイトルのタスクを作成
          todo ptaskremove x y
          ⇒　x番のプライベートリスト内のy番のタスクを削除
          todo ptaskremove x all
          ⇒　x番のプライベートリスト内のタスクを全て削除
          todo ptaskdone x y
          ⇒　x番のプライベートリスト内のy番のタスクを完了にする
          todo ptaskdone x all
          ⇒　x番のプライベートリスト内のタスクを全て完了にする
          todo ptaskcancel x y
          ⇒　x番のプライベートリスト内のy番のタスクの完了を取り消す
          todo ptaskcancel x all
          ⇒　x番のプライベートリスト内の完了しているタスクの全ての完了を取り消す
          todo ptaskedit x y 新しいタイトル名
          ⇒　x番のプライベートリスト内のy番のタスクのタイトルを新しいタイトル名に上書き
        HELP
      end
    end
  end
end
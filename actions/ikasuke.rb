require 'json'
require 'time'
module Ruboty
  module Actions
    class Ikasuke < Base
      BRAND_LIST =
        {
          "アイロニック" => {good: "スーパージャンプ時間短縮", bad: "復活時間短縮"},
          "アナアキ" => {good: "マーキング時間短縮", bad: "スペシャル減少ダウン"},
          "アロメ" => {good: "インク回復力アップ", bad: "スーパージャンプ時間短縮"},
          "エゾッコ" => {good: "スペシャル減少量ダウン", bad: "スペシャル増加量アップ"},
          "エンペリー" => {good: "サブ性能アップ", bad: "相手インク影響軽減"},
          "クラーゲス" => {good: "イカダッシュ速度アップ", bad: "爆風ダメージ軽減"},
          "シグレニ" => {good: "爆風ダメージ軽減", bad: "マーキング時間短縮"},
          "ジモン" => {good: "インク効率アップ（メイン）", bad: "ヒト移動速度アップ"},
          "タタキケンサキ" => {good: "マーキング時間短縮", bad: "サブ性能アップ"},
          "バトロイカ" => {good: "相手インク影響軽減", bad: "インク効率アップ（メイン）"},
          "フォーリマ" => {good: "スペシャル性能アップ", bad: "インク効率アップ（サブ）"},
          "ホタックス" => {good: "復活時間短縮", bad: "スペシャル減少量ダウン"},
          "ホッコリー" => {good: "インク効率アップ（サブ）", bad: "インク回復力アップ"},
          "ロッケンベルグ" => {good: "ヒト移動速度アップ", bad: "イカダッシュ速度アップ"},
          "ヤコ" => {good: "スペシャル増加量アップ", bad: "スペシャル性能アップ"},
          "アタリメイド" => {good: "なし", bad: "なし"},
          "アミーボ" => {good: "なし", bad: "なし"},
          "クマサン商会" => {good: "なし", bad: "なし"},
        }

      GPOWER_LIST =
        {
          "相手インク影響軽減" => "バトロイカ",
          "安全靴" => "バトロイカ",
          "インクアップ効率(メイン)" => "ジモン",
          "メインク" => "ジモン",
          "ヒト移動速度アップ" => "ロッケンベルグ",
          "人速" => "ロッケンベルグ",
          "ヒト速" => "ロッケンベルグ",
          "イカダッシュ速度アップ" => "クラーゲス",
          "イカ速" => "クラーゲス",
          "爆風ダメージ軽減" => "シグレニ",
          "爆風ダメ軽減" => "シグレニ",
          "爆風軽減" => "シグレニ",
          "爆風" => "シグレニ",
          "スーパージャンプ時間短縮" => "アイロニック",
          "スパジャン短縮" => "アイロニック",
          "スパジャン" => "アイロニック",
          "復活時間短縮" => "ホタックス",
          "復活時間" => "ホタックス",
          "復活" => "ホタックス",
          "ゾンビ" => "ホタックス",
          "スペシャル減少量ダウン" => "エゾッコ",
          "スペ減" => "エゾッコ",
          "スペシャル増加量" => "ヤコ",
          "スペ増" => "ヤコ",
          "スペシャル性能アップ" => "フォーリマ",
          "スペ強" => "フォーリマ",
          "スペ性" => "フォーリマ",
          "インク効率アップ(サブ)" => "ホッコリー",
          "サブインク" => "ホッコリー",
          "サインク" => "ホッコリー",
          "インク回復力アップ" => "アロメ",
          "インク回復力" => "アロメ",
          "インク回復" => "アロメ",
          "サブ性能アップ" => "エンペリー",
          "サブ性能" => "エンペリー",
          "サブ強化" => "エンペリー",
          "マーキング時間短縮" => "アナアキ or タタキケンサキ",
          "マキガ" => "アナアキ or タタキケンサキ",
      }

      def self.brand_list(message)
        body = ''
        BRAND_LIST.each do |key, value|
          body << "--------------------------\n"
          body << "#{key}=> 付きやすい : #{value[:good]} 付きにくい : #{value[:bad]}\n"
        end
        message.reply body
      end

      def self.brand(message)
        begin
          message.reply "付きやすいギア : " + BRAND_LIST[message[:brand_name]][:good]
          message.reply "付きにくいギア : " + BRAND_LIST[message[:brand_name]][:bad]
        rescue NoMethodError
          message.reply "ブランドがみつかりません"
        end
      end

      def self.gearpower_list(message)
        body = ''
        GPOWER_LIST.each do |key, value|
          body << "-------------------------\n"
          body << "#{key} が付きやすいブランドは #{value}\n"
        end
        message.reply body
      end

      def self.gearpower(message)
        begin
          message.reply "付きやすいブランド : " + GPOWER_LIST[message[:gpower_name]]
        rescue NoMethodError
          message.reply "Not Found"
        rescue TypeError => ex
          message.reply "TypeError"
        end
      end

      def self.gachi_rule_map(message)
        response = Faraday.get 'https://spla2.yuu26.com/gachi/now'
        gachi_json = JSON.parse(response.body)
        rule = gachi_json['result'][0]['rule']
        map1 = gachi_json['result'][0]['maps'][0]
        map2 = gachi_json['result'][0]['maps'][1]
        start_time = Time.parse(gachi_json['result'][0]['start'])
        end_time = Time.parse(gachi_json['result'][0]['end'])
        
        body = ''
        body << start_time.year.to_s + "年" + start_time.month.to_s + "月" + start_time.day.to_s + "日\n"
        body << start_time.hour.to_s + "時 - " + end_time.hour.to_s + "時\n"
        body << "ルール : " + rule + "\nマップ : " + map1 + " / " + map2
        message.reply body
      end

      def self.nawabari_rule_map(message)
        response = Faraday.get 'https://spla2.yuu26.com/regular/now'
        nawabari_json = JSON.parse(response.body)
        rule = nawabari_json['result'][0]['rule']
        map1 = nawabari_json['result'][0]['maps'][0]
        map2 = nawabari_json['result'][0]['maps'][1]
        start_time = Time.parse(nawabari_json['result'][0]['start'])
        end_time = Time.parse(nawabari_json['result'][0]['end'])

        body = ''
        body << start_time.year.to_s + "年" + start_time.month.to_s + "月" + start_time.day.to_s + "日\n"
        body << start_time.hour.to_s + "時 - " + end_time.hour.to_s + "時\n"
        body << "ルール : " + rule + "\nマップ : " + map1 + " / " + map2
        message.reply body
      end

      def self.league_rule_map(message)
        response = Faraday.get 'https://spla2.yuu26.com/league/now'
        league_json = JSON.parse(response.body)
        rule = league_json['result'][0]['rule']
        map1 = league_json['result'][0]['maps'][0]
        map2 = league_json['result'][0]['maps'][1]
        start_time = Time.parse(league_json['result'][0]['start'])
        end_time = Time.parse(league_json['result'][0]['end'])

        body = ''
        body << start_time.year.to_s + "年" + start_time.month.to_s + "月" + start_time.day.to_s + "日\n"
        body << start_time.hour.to_s + "時 - " + end_time.hour.to_s + "時\n"
        body << "ルール : " + rule + "\nマップ : " + map1 + " / " + map2
        message.reply body
      end

      def self.salmon_weapon_map(message)
        response = Faraday.get 'https://spla2.yuu26.com/coop/schedule'
        salmon_json = JSON.parse(response.body)

        weapon_list = salmon_json['result'][0]['weapons'].map {|weapon| weapon['name']}
        weapon_text = weapon_list.join(" / ")

        start_time = Time.parse(salmon_json['result'][0]['start'])
        end_time = Time.parse(salmon_json['result'][0]['end'])

        map = salmon_json['result'][0]['stage']['name']

        body = ''
        body << start_time.year.to_s + "年" + start_time.month.to_s + "月" + start_time.day.to_s + "日\n"
        body << start_time.hour.to_s + "時 - " + end_time.hour.to_s + "時\n"
        body << "マップ : " + map + "\n"
        body << "ブキ : " + weapon_text
        message.reply body
      end

    end
  end
end

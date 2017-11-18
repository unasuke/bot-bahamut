module Ruboty
  module Handlers
    class Ikasuke < Base
      BRAND_LIST = {"アイロニック" => {good: "スーパージャンプ時間短縮", bad: "復活時間短縮"},
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
                    "ロッケンベルク" => {good: "ヒト移動速度アップ", bad: "イカダッシュ速度アップ"},
                    "ヤコ" => {good: "スペシャル増加量アップ", bad: "スペシャル性能アップ"},
                    "アタリメイド" => {good: "なし", bad: "なし"},
                    "アミーボ" => {good: "なし", bad: "なし"},
                    "クマサン商会" => {good: "なし", bad: "なし"},
                  }
      GPOWER_LIST = {"相手インク影響軽減" => "バトロイカ",
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
                     "スパジャン" => "アイロニック",
                     "復活時間短縮" => "ホタックス",
                     "復活時間" => "ホタックス",
                     "復活" => "ホタックス",
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
      on /brand (?<brand_name>.*?)\z/, name: 'brand', description: 'ブランド毎に付きやすい/付きにくいギア出力', all: true
      on /gpower (?<gpower_name>.*?)\z/, name: 'gpower', description: 'ギア名から付きやすいブランドを出力', all: true


      # ブランド名からギア詳細出力
      def brand(message)
        # 入力が"list"の時
        if message[:brand_name] == "list"
          BRAND_LIST.each do |key, value|
            message.reply("--------------------------")
            message.reply key
            message.reply "付きやすい : " + value[:good] + " 付きにくい : " + value[:bad]
          end
        # 入力がブランド名の時
        else
          begin
            message.reply "付きやすいギア : " + BRAND_LIST[message[:brand_name]][:good]
            message.reply "付きにくいギア : " + BRAND_LIST[message[:brand_name]][:bad]
          rescue NoMethodError => ex
            message.reply "Not Found"
          end
        end
      end

      # ギア名からブランド名出力
      def gpower(message)
        if message[:gpower_name] == "list"
          GPOWER_LIST.each do |key, value|
            message.reply "-------------------------"
            message.reply key + " が付きやすいブランドは " + value
          end
        else
          begin
            message.reply "付きやすいブランド : " + GPOWER_LIST[message[:gpower_name]]
          rescue NoMethodError => ex
            message.reply "Not Found"
          rescue TypeError => ex
            message.reply "TypeError"
          end
        end
      end
    end
  end
end

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
      on /brand (?<brand_name>.*?)\z/, name: 'brand', description: 'ブランド毎に付きやすい/付きにくいギア出力', all: true

      def brand(message)
        begin
          message.reply "付きやすいブランド : " + BRAND_LIST[message[:brand_name]][:good]
          message.reply "付きにくいブランド : " + BRAND_LIST[message[:brand_name]][:bad]
        rescue NoMethodError => ex
          message.reply "NoMethodError"
        end
      end
    end
  end
end

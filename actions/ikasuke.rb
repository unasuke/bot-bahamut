require 'json'
require 'time'
require 'yaml'

module Ruboty
  module Actions
    class Ikasuke < Base
      @@data = YAML.load_file("data.yaml")["splatoon"]

      def self.brand_list(message)
        body = ''
        @@data["brands"].each do |brand|
          body << "--------------------------\n"
          body << "#{brand["name"]} => 付きやすい : #{brand["good"]} 付きにくい : #{brand["bad"]}\n"
        end
        message.reply body
      end

      def self.brand(message)
        brand = @@data["brands"].find { |brand| brand["name"] == message[:brand_name] }
        if brand
          message.reply "付きやすいギア : " + brand["good"]
          message.reply "付きにくいギア : " + brand["bad"]
        else
          message.reply "ブランドがみつかりません"
        end
      end

      def self.gearpower_list(message)
        body = ''
        @@data["gear_powers"].each do |gear_power|
          body << "#{gear_power["name"]} が付きやすいブランドは #{gear_power["target"]}\n\n"
        end
        message.reply body
      end

      def self.gearpower(message)
        gear = @@data["gear_powers"].find { |gear| gear["name"] == message[:gpower_name] || gear["aliases"].include?(message[:gpower_name]) }
        if gear
          message.reply "付きやすいブランド : " + gear["target"]
        else
          message.reply "Not Found"
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
        body << start_time.year.to_s + "年" + start_time.month.to_s + "月" + start_time.day.to_s + "日 "
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
        body << start_time.year.to_s + "年" + start_time.month.to_s + "月" + start_time.day.to_s + "日 "
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
        body << start_time.year.to_s + "年" + start_time.month.to_s + "月" + start_time.day.to_s + "日 "
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
        body << start_time.year.to_s + "年" + start_time.month.to_s + "月" + start_time.day.to_s + "日" + start_time.hour.to_s + "時 - "
        body << end_time.year.to_s + "年" + end_time.month.to_s + "月" + end_time.day.to_s + "日" + end_time.hour.to_s + "時\n"
        body << "マップ : " + map + "\n"
        body << "ブキ : " + weapon_text
        message.reply body
      end
    end
  end
end

# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'anthropic'
gem 'readline-ext'
gem 'ruboty'
gem "sqlite3"

group :development do
  gem 'rubocop', require: false
end

group :production do
  gem 'ruboty-discord'
end

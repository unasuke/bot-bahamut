FROM ruby:4.0.2

RUN apt-get update && apt-get install -y libsqlite3-dev

LABEL service="bot-bahamut"

WORKDIR /bot-bahamut

COPY Gemfile Gemfile.lock /bot-bahamut/

RUN bundle install

COPY . .

CMD ["bundle", "exec", "ruboty", "--load", "handlers.rb"]
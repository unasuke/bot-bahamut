FROM ruby:3.4.9

WORKDIR /bot-bahamut
COPY Gemfile Gemfile.lock /bot-bahamut/
RUN bundle install
COPY . .

CMD ["bundle", "exec", "ruboty", "--load", "handlers.rb"]

FROM ruby:2.7.6

WORKDIR /bot-bahamut
COPY Gemfile Gemfile.lock /bot-bahamut/
RUN bundle install
COPY . .

CMD ["bundle", "exec", "ruboty", "--load", "handlers.rb"]

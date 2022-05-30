FROM ruby:2.7.2

WORKDIR /bot-bahamut
COPY ./Gemfile /bot-bahamut
COPY ./Gemfile.lock /bot-bahamut

RUN bundle install

FROM ruby:2.7

RUN mkdir /app
WORKDIR /app
COPY . /app
RUN bundle install


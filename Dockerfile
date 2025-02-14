FROM ruby:3.2

ENV APP_HOME /app
WORKDIR $APP_HOME

COPY . .

RUN bundle install

EXPOSE 9292

CMD ["rackup", "-o", "0.0.0.0", "-p", "9292"]

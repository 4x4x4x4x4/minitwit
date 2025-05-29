FROM ruby:3.2

ENV APP_HOME /app
WORKDIR $APP_HOME

COPY . ./src

RUN bundle install

EXPOSE 5000

CMD ["rackup", "-o", "0.0.0.0", "-p", "5000"]

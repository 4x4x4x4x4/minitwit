FROM ruby:3.2

ENV APP_HOME /app
WORKDIR $APP_HOME

# Install dependencies for building native extensions
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs \
  git \
  curl

# Copy Gemfiles and install gems
COPY src/Gemfile ./
RUN bundle install

# Copy the rest of the application code
COPY src/ .

EXPOSE 5000

CMD ["rackup", "-o", "0.0.0.0", "-p", "5000"]

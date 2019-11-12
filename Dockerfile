# docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app ruby:2.6 bundle lock
FROM ruby:2.6
WORKDIR /usr/src/app
RUN apt-get update && apt-get install -y pdftk libmagickwand-dev

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
CMD ["rackup", "-p", "4567", "-o", "0.0.0.0"]
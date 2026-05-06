# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.2.0
ARG DISTRO_NAME=bullseye

# --- Build stage ---
FROM ruby:$RUBY_VERSION-slim-$DISTRO_NAME AS build

WORKDIR /applelink

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git pkg-config

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install --without development test && \
    rm -rf ~/.bundle/cache /usr/local/bundle/cache

COPY . .

# --- Runtime stage ---
FROM ruby:$RUBY_VERSION-slim-$DISTRO_NAME

WORKDIR /applelink

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips jq && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /applelink /applelink

ENV LD_PRELOAD=libjemalloc.so.2

EXPOSE 4000

CMD ["bundle", "exec", "rackup", "-s", "puma", "config.ru", "-p", "4000", "-o", "0.0.0.0"]

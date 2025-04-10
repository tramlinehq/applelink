# syntax = docker/dockerfile:1

# docker build -t my-app .
# docker run -d -p 80:80 -p 443:443 --name my-app -e RAILS_MASTER_KEY=<value from config/master.key> my-app
# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.0
ARG DISTRO_NAME=bullseye

FROM ruby:$RUBY_VERSION-slim-$DISTRO_NAME AS base

ARG DISTRO_NAME

# Rails app lives here
WORKDIR /applelink

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips gnupg2 less build-essential git pkg-config jq vim libnss3-tools

# Copy application code
COPY . .
RUN bundle install

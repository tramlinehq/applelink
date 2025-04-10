# syntax = docker/dockerfile:1

# Multi-platform build example:
# docker buildx build --platform linux/amd64,linux/arm64 -t my-app:latest --push .

# docker build -t my-app .
# docker run -d -p 80:80 -p 443:443 --name my-app -e RAILS_MASTER_KEY=<value from config/master.key> my-app
# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.0
ARG DISTRO_NAME=bullseye

FROM --platform=${BUILDPLATFORM:-linux/amd64} ruby:$RUBY_VERSION-slim-$DISTRO_NAME AS base

# Rails app lives here
WORKDIR /applelink

# Install essential dependencies only in a single layer to reduce image size
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    gnupg2 \
    less \
    git \
    libnss3-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a builder stage that installs build dependencies
FROM --platform=${BUILDPLATFORM:-linux/amd64} base AS builder

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    pkg-config \
    libvips-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy .ruby-version file first (needed by Gemfile)
COPY .ruby-version ./

# Copy gemfile and install dependencies
COPY Gemfile Gemfile.lock ./

# Use specific bundler version to match Gemfile.lock
RUN gem install bundler -v 2.4.2 && \
    bundle config set --local without 'development test' && \
    bundle install --jobs=4 --retry=3

# Copy application code
COPY . .

# Final image with runtime dependencies only
FROM --platform=${TARGETPLATFORM:-linux/amd64} base

# Install runtime dependencies only
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    libvips42 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy gems from builder stage
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /applelink /applelink

EXPOSE 9292
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

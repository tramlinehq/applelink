ARG RUBY_VERSION=3.2.0
ARG DISTRO_NAME=bullseye

FROM --platform=${BUILDPLATFORM:-linux/amd64} ruby:$RUBY_VERSION-slim-$DISTRO_NAME AS base

WORKDIR /applelink

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

FROM --platform=${BUILDPLATFORM:-linux/amd64} base AS builder

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    pkg-config \
    libvips-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock .ruby-version ./

RUN gem install bundler -v 2.4.2 && \
    bundle config set --local without 'development test' && \
    bundle install --jobs=4 --retry=3

COPY . .

FROM --platform=${TARGETPLATFORM:-linux/amd64} base

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    libvips42 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /applelink /applelink

EXPOSE 9292

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

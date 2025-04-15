ARG RUBY_VERSION=3.2.0
ARG DISTRO_NAME=bullseye

FROM --platform=${BUILDPLATFORM:-linux/amd64} ruby:$RUBY_VERSION-slim-$DISTRO_NAME AS runtime

ENV DEBIAN_FRONTEND=noninteractive \
    BUNDLE_PATH="/usr/local/bundle"

WORKDIR /applelink

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    gnupg2 \
    less \
    git \
    libnss3-tools \
    libvips42 && \
    rm -rf /var/lib/apt/lists/*

FROM runtime AS builder

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    pkg-config \
    libvips-dev && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock .ruby-version ./

RUN gem install bundler:2.4.2 && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

COPY . .

FROM runtime

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /applelink /applelink

EXPOSE 9292

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

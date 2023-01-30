require "sentry-ruby"

module Initializers
  module SentryConfig
    puts "Initializing Sentry..."
    Sentry.init do |config|
      config.dsn = ENV["SENTRY_DSN"]
      config.breadcrumbs_logger = [:sentry_logger, :http_logger]
      config.enabled_environments = %w[production]

      # To activate performance monitoring, set one of these options.
      # We recommend adjusting the value in production:
      config.traces_sample_rate = 1.0
      # or
      config.traces_sampler = lambda do |context|
        true
      end
    end
  end
end

require "sentry-ruby"

module Initializers
  module SentryConfig
    puts "Initializing Sentry..."
    Sentry.init do |config|
      config.dsn = ENV["SENTRY_DSN"]
      config.breadcrumbs_logger = [:sentry_logger, :http_logger]
      config.enabled_environments = %w[production]
      # config.traces_sample_rate = 0.2
      config.traces_sampler = lambda do |_|
        return 0.0 if ENV["RACK_ENV"].eql?("staging")
        0.2
      end
      config.logger.level = Logger::WARN
    end
  end
end

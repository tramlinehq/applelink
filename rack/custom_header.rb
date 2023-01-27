require "rack/request"

module Rack
  class CustomHeader
    CUSTOM_HEADERS = %w[HTTP_X_APPSTORECONNECT_KEY_ID HTTP_X_APPSTORECONNECT_ISSUER_ID HTTP_X_APPSTORECONNECT_TOKEN].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      if any_missing_headers?(env)
        return [422, { 'Content-Type' => 'text/plain' }, ['Missing required custom headers to fulfill the request.']]
      end

      @app.call env
    end

    private

    def any_missing_headers?(env)
      CUSTOM_HEADERS.any? { |header| missing_header?(env, header) }
    end

    def missing_header?(env, header)
      puts env[header]
      env[header].nil? || env[header].strip.empty?
    end
  end
end
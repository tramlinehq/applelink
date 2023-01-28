require "rack/request"

module Rack
  class AppStoreConnectHeaders
    HEADERS = {
      "HTTP_X_APPSTORECONNECT_KEY_ID" => :key_id,
      "HTTP_X_APPSTORECONNECT_ISSUER_ID" => :issuer_id,
      "HTTP_X_APPSTORECONNECT_TOKEN" => :token
    }

    def initialize(app)
      @app = app
    end

    def call(env)
      if any_missing_headers?(env)
        return [422, {"Content-Type" => "text/plain"}, ["Missing required custom headers to fulfill the request."]]
      end

      env[:app_store_connect_params] = {}
      HEADERS.keys.each do |header|
        env[:app_store_connect_params][HEADERS[header]] = env[header]
      end

      @app.call env
    end

    private

    def any_missing_headers?(env)
      HEADERS.keys.any? { |header| missing_header?(env, header) }
    end

    def missing_header?(env, header)
      env[header].nil? || env[header].strip.empty?
    end
  end
end

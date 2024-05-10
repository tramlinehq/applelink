require "rack/request"
require_relative "../spaceship/wrapper_token"
require_relative "./applelink_util"

module Rack
  class AppStoreAuthHandler
    include Rack::AppleLinkUtil

    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call env
    rescue Spaceship::WrapperToken::TokenExpiredError => e
      env[RACK_LOGGER].error e
      return_unauthorized_error({message: "Invalid auth token for apple store connect API"})
    end
  end
end

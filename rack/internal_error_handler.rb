require "rack/request"
require_relative "./applelink_util"
require_relative "../lib/app_store/errors"

module Rack
  class InternalErrorHandler
    include Rack::AppleLinkUtil

    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call env
    rescue *AppStore::ERRORS => e
      env[RACK_LOGGER].error e
      return_unprocessable_error e.message
    end
  end
end

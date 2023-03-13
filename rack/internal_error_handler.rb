require "rack/request"
require "sentry-ruby"
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
      log(env, e)
      return_unprocessable_error e.as_json
    rescue *AppStore::NOT_FOUND_ERRORS => e
      log(env, e)
      return_not_found_error e.as_json
    rescue *AppStore::CONFLICT_ERRORS => e
      log(env, e)
      return_conflict_error e.as_json
    end

    private

    def log(env, e)
      env[RACK_LOGGER].error e
      Sentry.capture_exception(e)
    end
  end
end

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
      return_unprocessable_error e.message
    rescue *AppStore::NOT_FOUND_ERRORS => e
      log(env, e)
      return_not_found_error e.message
    rescue *AppStore::CONFLICT_ERRORS => e
      log(env, e)
      return_conflict_error e.message
    end

    private

    def log(env, e)
      env[RACK_LOGGER].error e
      Sentry.capture_exception(e)
    end
  end
end

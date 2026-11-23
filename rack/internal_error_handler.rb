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
    rescue Spaceship::ProgramLicenseAgreementUpdated => e
      forbidden(env, e, AppStore::AgreementMissingError.new)
    rescue Spaceship::AccessForbiddenError => e
      forbidden(env, e, AppStore::ApiKeyForbiddenError.new)
    end

    private

    # These come from the customer's App Store Connect account, not from us,
    # so they are logged but not sent to Sentry.
    def forbidden(env, original, error)
      env[RACK_LOGGER].error original
      return_forbidden_error error.as_json
    end

    def log(env, e)
      env[RACK_LOGGER].error e
      Sentry.capture_exception(e)
    end
  end
end

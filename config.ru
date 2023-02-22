require "bundler/setup"
require "hanami/api"
require "hanami/middleware/body_parser"
require "sentry-ruby"
require "rack/jwt/auth"
require "rack/jwt"
require "./initializers/config"
require "./initializers/sentry_config"
require "./initializers/jwt"
require "./initializers/env"
require "./rack/app_store_connect_headers"
require "./rack/app_store_auth_handler"
require "./rack/internal_error_handler"
require "./lib/app_store/connect"
require "./lib/internal"

class InternalApp < Hanami::API
  get "keys" do
    json(Internal.keys(params))
  end
end

class AppleAppV1 < Hanami::API
  use Rack::JWT::Auth, Initializers::JWT.options
  use Rack::AppStoreConnectHeaders
  use Rack::AppStoreAuthHandler
  use Rack::InternalErrorHandler

  DOMAIN = AppStore::Connect

  helpers do
    def not_found(message)
      halt(404, json({error: message}))
    end
  end

  scope "/apps/:bundle_id" do
    get "/" do
      json(DOMAIN.metadata(**env[:app_store_connect_params].merge(params)))
    end

    get "/current_status" do
      json(DOMAIN.current_app_info(**env[:app_store_connect_params].merge(params)))
    end

    get "builds/:build_number" do
      json(DOMAIN.build(**env[:app_store_connect_params].merge(params)))
    end

    get "versions" do
      json(DOMAIN.versions(**env[:app_store_connect_params].merge(params)))
    end

    post "release_submissions" do
      json(DOMAIN.create_release_submission(**env[:app_store_connect_params].merge(params)))
    end

    scope "/live_release" do
      patch "pause_rollout" do
        DOMAIN.pause_phased_release(**env[:app_store_connect_params].merge(params))
        status(204)
      end

      patch "resume_rollout" do
        DOMAIN.resume_phased_release(**env[:app_store_connect_params].merge(params))
        status(204)
      end

      patch "halt_rollout" do
        DOMAIN.halt_release(**env[:app_store_connect_params].merge(params))
        status(204)
      end
    end

    scope "/groups" do
      get "/" do
        params[:internal] = params[:internal].nil? ? "nil" : params[:internal]
        json(DOMAIN.groups(**env[:app_store_connect_params].merge(params)))
      end

      patch "/:group_id/add_build" do
        DOMAIN.send_to_group(**env[:app_store_connect_params].merge(params))
        status(204)
      end
    end
  end
end

class App < Hanami::API
  include Initializers::Config
  extend Initializers::Env
  include Initializers::SentryConfig

  use Sentry::Rack::CaptureExceptions
  use Rack::Logger
  use Hanami::Middleware::BodyParser, :json

  get("/ping") { "pong" }
  mount AppleAppV1.new, at: "/apple/connect/v1"
  mount InternalApp.new, at: "/internal" if development?
end

run App.new

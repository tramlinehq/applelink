#\ -q

require "bundler/setup"
require "hanami/api"
require "hanami/middleware/body_parser"
require "sentry-ruby"
require "rack/jwt/auth"
require "rack/jwt"
require "rack/runtime"
require "./initializers/config"
require "./initializers/sentry_config"
require "./initializers/jwt"
require "./initializers/env"
require "./rack/app_store_connect_headers"
require "./rack/app_store_auth_handler"
require "./rack/internal_error_handler"
require "./rack/rack_ougai_logger"
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

  scope "apps/:bundle_id" do
    get "/" do
      json(DOMAIN.metadata(**env[:app_store_connect_params].merge(params)))
    end

    get "current_status" do
      json(DOMAIN.current_app_info(**env[:app_store_connect_params].merge(params)))
    end

    scope "builds" do
      get ":build_number" do
        json(DOMAIN.build(**env[:app_store_connect_params].merge(params)))
      end

      get "latest" do
        json(DOMAIN.latest_build(**env[:app_store_connect_params].merge(params)))
      end

      patch ":build_number" do
        DOMAIN.update_build_notes(**env[:app_store_connect_params].merge(params))
        status(204)
      end
    end

    scope "release" do
      post "prepare" do
        json(DOMAIN.prepare_release(**env[:app_store_connect_params].merge(params)))
      end

      patch "submit" do
        DOMAIN.create_review_submission(**env[:app_store_connect_params].merge(params))
        status(204)
      end

      patch "cancel_submission" do
        json(DOMAIN.cancel_review_submission(**env[:app_store_connect_params].merge(params)))
      end

      patch "start" do
        DOMAIN.start_release(**env[:app_store_connect_params].merge(params))
        status(204)
      end

      get "/" do
        json(DOMAIN.release(**env[:app_store_connect_params].merge(params)))
      end

      scope "live" do
        get "/" do
          json(DOMAIN.live_release(**env[:app_store_connect_params].merge(params)))
        end

        scope "rollout" do
          patch "pause" do
            json(DOMAIN.pause_phased_release(**env[:app_store_connect_params].merge(params)))
          end

          patch "resume" do
            json(DOMAIN.resume_phased_release(**env[:app_store_connect_params].merge(params)))
          end

          patch "complete" do
            json(DOMAIN.complete_phased_release(**env[:app_store_connect_params].merge(params)))
          end

          patch "halt" do
            DOMAIN.halt_release(**env[:app_store_connect_params].merge(params))
            status(204)
          end
        end
      end
    end

    scope "groups" do
      get "/" do
        params[:internal] = params[:internal].nil? ? "nil" : params[:internal]
        json(DOMAIN.groups(**env[:app_store_connect_params].merge(params)))
      end

      patch ":group_id/add_build" do
        DOMAIN.send_to_group(**env[:app_store_connect_params].merge(params))
        status(204)
      end
    end

    post "upload" do
      json(DOMAIN.upload_ipa(**env[:app_store_connect_params].merge(params)))
    end
  end
end

class App < Hanami::API
  include Initializers::Config
  extend Initializers::Env
  include Initializers::SentryConfig

  use Rack::Ougai::Logger
  use Rack::Ougai::RequestLogger
  use Rack::Runtime
  use Sentry::Rack::CaptureExceptions
  use Hanami::Middleware::BodyParser, :json

  get("ping") { "pong" }
  mount AppleAppV1.new, at: "apple/connect/v1"
  mount InternalApp.new, at: "internal" if development?
end

run App.new

require "bundler/setup"
require "hanami/api"
require "rack/jwt/auth"
require "rack/jwt"
require "rack/contrib"
require "./initializers/config"
require "./initializers/jwt"
require "./rack/app_store_connect_headers"
require "./rack/app_store_auth_handler"
require "./rack/internal_error_handler"
require "./lib/app_store/connect"

class AppleAppV1 < Hanami::API
  use Rack::JWT::Auth, Initializers::JWT.options
  use Rack::AppStoreConnectHeaders
  use Rack::AppStoreAuthHandler
  use Rack::InternalErrorHandler

  helpers do
    def not_found(message)
      halt(404, json({error: message}))
    end
  end

  scope "/apps/:bundle_id" do
    get "/" do
      AppStore::Connect
        .new(params[:bundle_id], **env[:app_store_connect_params])
        .metadata
        .then { |metadata| json(metadata) }
    end

    scope "/groups" do
      get "/" do
        internal = params[:internal].nil? ? "nil" : params[:internal]

        AppStore::Connect
          .new(params[:bundle_id], **env[:app_store_connect_params])
          .groups(internal:)
          .then { |groups| json(groups) }
      end

      put "/:group_id/add_build" do
        AppStore::Connect
          .new(params[:bundle_id], **env[:app_store_connect_params])
          .add_build_to_group(group_id: params[:group_id], build_number: params[:build_number])
          .then { |_| status(202) }
      end
    end

    get "builds/:build_number" do
      AppStore::Connect
        .new(params[:bundle_id], **env[:app_store_connect_params])
        .build(params[:build_number].to_s)
        .then { |build| json(build) }
    end

    get "versions" do
      AppStore::Connect
        .new(params[:bundle_id], **env[:app_store_connect_params])
        .versions
        .then { |builds| json(builds) }
    end
  end
end

class App < Hanami::API
  include Initializers::Config
  use Rack::Logger
  use Rack::JSONBodyParser

  get "/ping" do
    "pong"
  end

  mount AppleAppV1.new, at: "/apple/connect/v1"
end

run App.new

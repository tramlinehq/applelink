require "bundler/setup"
require "hanami/api"
require "rack/jwt/auth"
require "rack/jwt"
require "./initializers/config"
require "./initializers/jwt"
require "./rack/app_store_connect_headers"
require "./rack/app_store_auth_handler"
require "./app_store"

class AppleAppV1 < Hanami::API
  use Rack::JWT::Auth, Initializers::JWT.options
  use Rack::AppStoreConnectHeaders
  use Rack::AppStoreAuthHandler

  scope "/apps/:bundle_id" do
    get "/" do
      AppStore
        .new(params[:bundle_id], **env[:app_store_connect_params])
        .metadata
        .then { |metadata| metadata ? json(metadata) : halt(404, json({error: "App not found"})) }
    end

    get "groups" do
      internal = params[:internal].nil? ? "nil" : params[:internal]

      AppStore
        .new(params[:bundle_id], **env[:app_store_connect_params])
        .groups(internal:)
        .then { |groups| json(groups) }
    end

    get "builds/:build_number" do
      AppStore
        .new(params[:bundle_id], **env[:app_store_connect_params])
        .build(params[:build_number].to_s)
        .then { |build| build ? json(build) : halt(404, json({error: "Build not found"})) }
    end

    get "versions" do
      AppStore
        .new(params[:bundle_id], **env[:app_store_connect_params])
        .versions
        .then { |builds| json(builds) }
    end
  end
end

class App < Hanami::API
  include Initializers::Config
  use Rack::Logger

  get "/ping" do
    "pong"
  end

  mount AppleAppV1.new, at: "/apple/connect/v1"
end

run App.new

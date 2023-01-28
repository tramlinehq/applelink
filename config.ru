require "bundler/setup"
require "hanami/api"
require "rack/jwt/auth"
require "rack/jwt"
require "./initializers/config"
require "./initializers/jwt"
require "./rack/app_store_connect_headers"
require "./app_store"

class AppleAppV1 < Hanami::API
  use Rack::JWT::Auth, Initializers::JWT.options
  use Rack::AppStoreConnectHeaders

  scope "/apps/:bundle_id" do
    get "/" do
      AppStore
        .new(params[:bundle_id], **env[:app_store_connect_params])
        .metadata
        .then { |metadata| metadata ? json(metadata) : halt(404, "App not found") }
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
        .builds(params[:build_number].to_s)
        .then { |builds| not(builds.empty?) ? json(builds.first) : halt(404, "Build not found") }
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

  get "/ping" do
    "pong"
  end

  mount AppleAppV1.new, at: "/apple/connect/v1"
end

run App.new

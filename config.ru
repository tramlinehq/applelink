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

    scope "/groups" do
      get "/" do
        params[:internal] = params[:internal].nil? ? "nil" : params[:internal]
        json(DOMAIN.groups(**env[:app_store_connect_params].merge(params)))
      end

      patch "/:group_id/add_build" do
        DOMAIN.send_to_group(**env[:app_store_connect_params].merge(params))
        status(202)
      end
    end

    get "builds/:build_number" do
      json(DOMAIN.build(**env[:app_store_connect_params].merge(params)))
    end

    get "versions" do
      json(DOMAIN.versions(**env[:app_store_connect_params].merge(params)))
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
  mount InternalApp.new, at: "/internal" if ENV["APP_ENV"].eql?("development")
end

run App.new

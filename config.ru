require "bundler/setup"
require "dotenv"
require "hanami/api"
require "rack/jwt/auth"
require "rack/jwt"
require "./app_store"

puts "Loading config..."
Dotenv.load
Dotenv.require_keys("AUTH_ISSUER", "AUTH_SECRET", "AUTH_AUD")

class App < Hanami::API
  jwt_options = {
    secret: ENV["AUTH_SECRET"],
    options: {
      algorithm: 'HS256',
      verify_expiration: true,
      iss: ENV["AUTH_ISSUER"],
      verify_iss: true,
      aud: ENV["AUTH_AUDIENCE"],
      verify_aud: true
    },
    exclude: %w(/ping)
  }

  use Rack::JWT::Auth, jwt_options

  get "/ping" do
    "pong"
  end

  scope "apple/connect/v1/apps/:bundle_id" do
    get "/" do
      AppStore
        .new(params[:bundle_id])
        .metadata
        .then { |metadata| metadata ? json(metadata) : [404, "App not found"] }
    end

    get "groups" do
      internal = params[:internal].nil? ? "nil" : params[:internal]

      AppStore
        .new(params[:bundle_id])
        .groups(internal:)
        .then { |groups| json(groups) }
    end

    get "builds/:build_number" do
      AppStore
        .new(params[:bundle_id])
        .builds(params[:build_number].to_s)
        .then { |builds| json(builds) }
    end

    get "versions" do
      AppStore
        .new(params[:bundle_id])
        .versions
        .then { |builds| json(builds) }
    end
  end
end

run App.new

require "bundler/setup"
require "dotenv"
require "hanami/api"
require "rack/jwt/auth"
require "rack/jwt"
require "./app_store"
require "./rack/custom_header"

puts "Loading config..."
Dotenv.load
Dotenv.require_keys("AUTH_ISSUER", "AUTH_SECRET", "AUTH_AUD")

class AppleAppV1 < Hanami::API
  use Rack::CustomHeader

  scope "/apps/:bundle_id" do
    get "/" do
      AppStore
        .new(params[:bundle_id])
        .metadata
        .then { |metadata| metadata ? json(metadata) : halt(404, "App not found") }
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

  mount AppleAppV1.new, at: "/apple/connect/v1"
end

run App.new

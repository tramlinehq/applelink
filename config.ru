require "bundler/setup"
require "hanami/api"
require "./app_store"

class App < Hanami::API
  get "/ping" do
    "pong"
  end

  scope "apple/connect/v1/apps/:bundle_id" do
    get "/" do
      AppStore
        .new(params[:bundle_id])
        .metadata
        .then { |metadata| metadata ? json(metadata) : [404, "App not found"]}
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

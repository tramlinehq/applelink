require "bundler/setup"
require "hanami/api"
require "./app_store"

class App < Hanami::API
  scope "appstoreconnect" do
    get "groups" do
      internal = params[:internal].nil? ? "nil" : params[:internal]

      AppStore
        .new("com.tramline.ueno")
        .groups(internal:)
        .then { |groups| json(groups) }
    end

    get "builds/:build_number" do
      AppStore
        .new("com.tramline.ueno")
        .builds(params[:build_number].to_s)
        .then { |builds| json(builds) }
    end
  end
end

run App.new

require "bundler/setup"
require "hanami/api"
require "./app_store"

class App < Hanami::API
  get "/appstoreconnect/groups" do
    json(AppStore.new("com.tramline.ueno").groups)
  end
end

run App.new

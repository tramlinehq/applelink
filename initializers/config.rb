require "dotenv"

module Initializers
  module Config
    puts "Loading config..."
    Dotenv.overload
    Dotenv.require_keys("AUTH_ISSUER", "AUTH_SECRET", "AUTH_AUD")
  end
end

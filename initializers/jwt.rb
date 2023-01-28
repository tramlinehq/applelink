module Initializers
  module JWT
    def self.options
      {
        secret: ENV["AUTH_SECRET"],
        options: {
          algorithm: "HS256",
          verify_expiration: true,
          iss: ENV["AUTH_ISSUER"],
          verify_iss: true,
          aud: ENV["AUTH_AUDIENCE"],
          verify_aud: true
        }
      }
    end
  end
end

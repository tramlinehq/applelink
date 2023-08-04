require "spaceship"
require "jwt"

module Internal
  def self.keys(params)
    token =
      Spaceship::ConnectAPI::Token.create(
        key_id: params[:key_id],
        issuer_id: params[:issuer_id],
        filepath: File.absolute_path("key.p8")
      )

    payload = {
      iat: Time.now.to_i,
      exp: Time.now.to_i + 10000,
      aud: ENV["AUTH_AUD"],
      iss: ENV["AUTH_ISSUER"]
    }

    {
      store_token: token.text,
      auth_token: JWT.encode(payload, ENV["AUTH_SECRET"], "HS256")
    }
  end
end

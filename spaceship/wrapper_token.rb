require "jwt"

module Spaceship
  class WrapperToken
    class NotImplementedError < StandardError; end

    attr_reader :key_id
    attr_reader :issuer_id
    attr_reader :text
    attr_reader :duration
    attr_reader :expiration

    def self.from(_hash: nil, _filepath: nil)
      raise NotImplementedError
    end

    def self.from_json_file(_filepath)
      raise NotImplementedError
    end

    def self.create(_key_id: nil, _issuer_id: nil, _filepath: nil, _key: nil, _is_key_content_base64: false, _duration: nil, _in_house: nil, **)
      raise NotImplementedError
    end

    def initialize(key_id: nil, issuer_id: nil, text: nil)
      @key_id = key_id
      @issuer_id = issuer_id
      @text = text

      payload = JWT.decode(text, nil, false).first
      @duration = payload["exp"] - payload["iat"]
      @expiration = Time.at(payload["exp"])
    end

    def expired?
      @expiration < Time.now
    end

    def refresh!
      raise NotImplementedError
    end

    def write_key_to_file(_path)
      raise NotImplementedError
    end
  end
end
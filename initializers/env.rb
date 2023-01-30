module Initializers
  module Env
    def development?
      ENV["RACK_ENV"].eql?("development")
    end
  end
end

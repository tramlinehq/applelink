module Rack
  module AppleLinkUtil
    def return_unauthorized_error(message)
      body = {error: message}.to_json
      headers = {"Content-Type" => "application/json", "Content-Length" => body.bytesize.to_s}

      [401, headers, [body]]
    end

    def return_not_found_error(message)
      body = {error: message}.to_json
      headers = {"Content-Type" => "application/json", "Content-Length" => body.bytesize.to_s}

      [404, headers, [body]]
    end
  end
end

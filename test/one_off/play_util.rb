require "spaceship"
require "json"

BID = "com.tramline.ueno"

def line
  pp "*" * 30
  puts "\n"
end

def version_data(version)
  version_data = {
    version_name: version.version_string,
    app_store_state: version.app_store_state,
    release_type: version.release_type,
    earliest_release_date: version.earliest_release_date,
    downloadable: version.downloadable,
    created_date: version.created_date,
    build_number: version.build&.version
  }
  puts JSON.pretty_generate(version_data)
end

def build_data(b)
  build_data = {
    build_number: b.version,
    version_string: b.app_version,
    details: b.get_build_beta_details
  }
  puts JSON.pretty_generate(build_data)
end

def set_auth_token
  token = Spaceship::ConnectAPI::Token.create(
    key_id: "KEY_ID",
    issuer_id: "ISSUER_ID",
    filepath: File.absolute_path("key.p8")
  )

  token.text
end

puts set_auth_token

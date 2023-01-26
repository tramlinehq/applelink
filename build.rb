require "spaceship"
require "json"

BID = "com.tramline.ueno"

token = Spaceship::ConnectAPI::Token.create(
  key_id: "2NK99Z483A",
  issuer_id: "54df29f3-21e4-4336-a67a-c1d738af5e80",
  filepath: File.absolute_path("key.p8")
)

Spaceship::ConnectAPI.token = token

def line
  pp "*" * 30
  puts "\n"
end

# Find app by bundle id
app = Spaceship::ConnectAPI::App.find(BID)

# App metadata
app_data = {
  id: app.id,
  name: app.name,
  bundle_id: app.bundle_id,
  sku: app.sku
}

puts JSON.pretty_generate(app_data)

# {
#   "id": "1658845856",
#   "name": "Ueno",
#   "bundle_id": "com.tramline.ueno",
#   "sku": "com.tramline.ueno"
# }

line

# List app store versions
app.get_app_store_versions.each do |app_version|

  version_data = {
    version_name: app_version.version_string,
    app_store_state: app_version.app_store_state,
    release_type: app_version.release_type,
    earliest_release_date: app_version.earliest_release_date,
    downloadable: app_version.downloadable,
    created_date: app_version.created_date,
    build_number: app_version.build.nil? ? nil : app_version.build.version
  }

  puts JSON.pretty_generate(version_data)

  # App store version metadata (versions that have been released/draft released)
  # {
  #   "version_name": "1.2.0",
  #   "app_store_state": "REJECTED",
  #   "release_type": "MANUAL",
  #   "earliest_release_date": null,
  #   "downloadable": true,
  #   "created_date": "2022-12-14T09:24:22-08:00",
  #   "build_number": "1002"
  # }

  line
end

app.get_builds(includes: "preReleaseVersion", sort: "-uploadedDate").each do |b|
  build_data = {
    build_number: b.version,
    version_string: b.app_version,
    details: b.get_build_beta_details
  }
  puts JSON.pretty_generate(build_data)

  # {
  #   "build_number": "7000",
  #   "version_string": "1.2.0",
  #   "details": [
  #     {
  #       "id": "484d9bfc-5fc1-41d9-a395-e7ada902c9b4",
  #       "auto_notify_enabled": true,
  #       "internal_build_state": "MISSING_EXPORT_COMPLIANCE",
  #       "external_build_state": "MISSING_EXPORT_COMPLIANCE"
  #     }
  #   ]
  # }
  # "******************************"
  #
  # {
  #   "build_number": "1002",
  #   "version_string": "7.0.0",
  #   "details": [
  #     {
  #       "id": "1a8ff754-6e41-42a3-a8b1-b4389a6f8961",
  #       "auto_notify_enabled": true,
  #       "internal_build_state": "IN_BETA_TESTING",
  #       "external_build_state": "READY_FOR_BETA_SUBMISSION"
  #     }
  #   ]
  # }
  # "******************************"
  #
  # {
  #   "build_number": "500",
  #   "version_string": "6.0.0",
  #   "details": [
  #     {
  #       "id": "7ab689d8-ba26-4d41-b97b-4ff6b9cf680b",
  #       "auto_notify_enabled": true,
  #       "internal_build_state": "IN_BETA_TESTING",
  #       "external_build_state": "BETA_APPROVED"
  #     }
  #   ]
  # }

  line
end

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

def version_data(version)
  version_data = {
    version_name: version.version_string,
    app_store_state: version.app_store_state,
    release_type: version.release_type,
    earliest_release_date: version.earliest_release_date,
    downloadable: version.downloadable,
    created_date: version.created_date,
    build_number: version.build.nil? ? nil : version.build.version
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

# Promotion of builds

platform = Spaceship::ConnectAPI::Platform.map("IOS")
version = app.get_edit_app_store_version(platform: platform)

version_data(version)

build = Spaceship::ConnectAPI::Build.all(
  app_id: app.id,
  version: "7.0.0",
  build_number: "1002",
  platform: platform
).first

build_data(build)

# STEP 1
# update_export_compliance(options, app, build) -- true/false
# build = build.update(attributes: {
#   usesNonExemptEncryption: uses_encryption
# })
# STEP 2
# update_idfa(options, app, version) -- THIS SEEMS TO BE NOT USED ANYMORE AFTER 2020

# STEP 3
# update_submission_information(options, app) -- third party content declararion
# app.update(attributes: {
#   contentRightsDeclaration: value
# })

# STEP 4
# create_review_submission(options, app, version, platform)

# Can't submit a review if there is already a review in progress
if app.get_in_progress_review_submission(platform: platform)
  puts "Cannot submit for review - A review submission is already in progress"
  exit
end

# There can only be one open submission per platform per app
# There might be a submission already created so we need to check
# 1. Create the submission if its not already created
# 2. Error if submission already contains some items for review (because we don't know what they are)
# submission object is of class Spaceship::ConnectAPI::ReviewSubmission
submission = app.get_ready_review_submission(platform: platform, includes: "items")
if submission.nil?
  submission = app.create_review_submission(platform: platform)
elsif !submission.items.empty?
  puts "Cannot submit for review - A review submission already exists with items not managed by fastlane. Please cancel or remove items from submission for the App Store Connect website"
  exit
end

submission.add_app_store_version_to_review_items(app_store_version_id: version.id)
submission.submit_for_review

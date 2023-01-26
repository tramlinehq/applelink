require "./play_util"

set_auth_token

# Find app by bundle id
app = Spaceship::ConnectAPI::App.find(BID)

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

require "spaceship"

token = Spaceship::ConnectAPI::Token.create(
  key_id: "2NK99Z483A",
  issuer_id: "54df29f3-21e4-4336-a67a-c1d738af5e80",
  filepath: File.absolute_path("key.p8")
)

Spaceship::ConnectAPI.token = token
#
# Spaceship::ConnectAPI::App.all.collect do |app|
#   puts app.name, app.id, app.bundle_id, app.sku
#   v1 = app.get_live_app_store_version
#   v2 = app.get_edit_app_store_version
#   v3 = app.get_latest_app_store_version
#   v4 = app.get_pending_release_app_store_version
#   v5 = app.get_in_review_app_store_version
#
#   [v1, v2, v3, v4, v5].each_with_index do |vurshun, idx|
#     next if vurshun.nil?
#     puts idx
#     build_number = vurshun.build.nil? ? nil : vurshun.build.version
#     pp [vurshun.app_store_state, vurshun.version_string, build_number]
#   end
# end

BID = "com.tramline.ueno"


def dl(n)
  puts "*" * n
end

# List all the external testing groups
# List all the internal testing groups that do not have auto-distribute
# Fetch app metadata
# Find build by build number
# Fetch per build metadata
# Promote a particular build to a particular group
# Promote a particular build to app store
# Check status of a particular build version

app =  Spaceship::ConnectAPI::App.find(BID)

app.get_beta_groups.each do |bg|
  p bg.name
  p bg.is_internal_group
  p bg.beta_testers
  p bg.fetch_builds.size

  dl 15

  testers = app.get_beta_testers
  testers.each do |t|
    p t.email
    p t.beta_groups
    p t.builds

    dl 15
  end
end

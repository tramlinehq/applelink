require "./play_util"
require "./spaceship/wrapper_token"

token = set_auth_token

token_obj = Spaceship::WrapperToken.new(
  key_id: "2NK99Z483A",
  issuer_id: "54df29f3-21e4-4336-a67a-c1d738af5e80",
  text: token
)

Spaceship::ConnectAPI.token = token_obj

# Find app by bundle id
app = Spaceship::ConnectAPI::App.find(BID)

build = Spaceship::ConnectAPI::Build.all(
  app_id: app.id,
  version: "7.0.0", # input from user
  build_number: "1002" # input from user
).first

build_data(build)

beta_group = app.get_beta_groups(filter: { name: "Opinions" }).first

puts beta_group.id

puts "Submitting build for review"

build.post_beta_app_review_submission

puts "Adding build to beta group - #{beta_group.name}"

build.add_beta_groups(beta_groups: [beta_group])

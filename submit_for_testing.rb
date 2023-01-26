require "./play_util"

set_auth_token

# Find app by bundle id
app = Spaceship::ConnectAPI::App.find(BID)


guard "rack", port: 4000 do
  watch("Gemfile.lock")
  watch(".env")
  watch(%r{^config|initializers|lib|rack|spaceship|lib/.*})
end

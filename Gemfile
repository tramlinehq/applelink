source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version").strip

gem "dotenv"
gem "fastlane"
gem "puma"
gem "hanami-api"
gem "rack-jwt"
gem "sentry-ruby"
gem "dry-logger"

group :development, :test do
  gem "standard"
  gem "guard-rack"
  gem "bundler-audit", "~> 0.9.1"
end

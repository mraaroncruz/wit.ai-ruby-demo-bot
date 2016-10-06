require "bundler/setup"
Bundler.require

require "./wit_ai"

require 'facebook/messenger'

include Facebook::Messenger

Facebook::Messenger.configure do |config|
  config.access_token = ENV.fetch("FACEBOOK_PAGE_ACCESS_TOKEN")
  config.app_secret   = ENV.fetch("FACEBOOK_APP_SECRET")
  config.verify_token = ENV.fetch("FACEBOOK_VERIFY_TOKEN")
end

$wit = WitAI.new

Bot.on :message do |message|
  $wit.run_actions(message)
end

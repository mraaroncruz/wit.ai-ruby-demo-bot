require 'facebook/messenger'
require_relative 'bot'

map "/webhook" do
  run(Facebook::Messenger::Server)
end

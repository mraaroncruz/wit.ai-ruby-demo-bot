require "awesome_print"
require "wit"
require "json"
require "securerandom"

require "./meetup"

class WitAI
  def initialize(access_token = ENV.fetch("WIT_ACCESS_TOKEN"))
    @client = Wit.new(access_token: access_token, actions: actions)
    @group = "vienna-rb"
    @meetup = Meetup::Client.new(ENV.fetch("MEETUP_API_KEY"))
    @sessions = {}
  end

  def user_logged_in?(id)
    !!@sessions[id]
  end

  def login(user_id)
    @sessions[user_id] ||= {}
    @sessions[user_id][:session_id] = SecureRandom.uuid
  end

  def user(session_id)
    _, user = @sessions.find { |k,v| v[:session_id] == session_id }
    user
  end

  def user_id(session_id)
    user_id, _ = @sessions.find { |k,v| v[:session_id] == session_id }
    user_id
  end

  def logout(session_id)
    user_id, _ = @sessions.find { |k,v| v[:session_id] == session_id }
    @sessions.delete(user_id) if user_id
  end

  def session_id(user_id)
    @sessions[user_id][:session_id]
  end

  def run_actions(message)
    user_id = message.sender["id"]
    login(user_id) unless user_logged_in?(user_id)
    context = @sessions
      .fetch(user_id, {})
      .fetch(:context, {})
    @client.run_actions(session_id(user_id), message.text, context)
  end

  def send_message(message)
    @client.message(message)
  end

  private

  def actions
    {
      send: -> (req, res) {
        text = res["text"]
        recipient = { id: user_id(req["session_id"]) }

        Bot.deliver(
          recipient: recipient,
          message: {
            text: text
          }
        )
      },

      merge: -> context {
        require 'pry'
        require 'pry-byebug'
        binding.pry
        event = @meetup.next_event(@group)
        context["context"]["location"] = event.location
        context["context"]["meetup_date"] = event.starts_at.strftime("%B %e")
        u = user(context["session_id"])
        u[:context] = context["context"]
        return context["context"]
      },

      end_conversation: -> (context) {
        logout(context["session_id"])
        context
      },

      error: -> error {
        puts "Error: #{err.to_json}"
      }
    }
  end
end

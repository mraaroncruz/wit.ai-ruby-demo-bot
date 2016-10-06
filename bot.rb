require "json"

require "bundler/setup"
Bundler.require

module Meetup
  class Data
    attr_reader :title
    attr_reader :status
    attr_reader :location
    attr_reader :lat
    attr_reader :lng
    attr_reader :description
    attr_reader :link

    def initialize(event)
      @title       = event["name"]
      @status      = event["status"]
      venue        = event["venue"]
      @location    = "%s — %s" % [venue["name"], venue["address_1"]]
      @lat         = venue["lat"]
      @lng         = venue["lon"]
      @description = event["description"]
      @link        = event["link"]
    end
  end

  class Client
    BASE_URL = "https://api.meetup.com"

    attr_reader :api_key

    def initialize(api_key)
      @api_key = api_key
    end

    def events(group_name)
      return @events if @events

      url = BASE_URL + "/#{group_name}/events?api_key=#{api_key}"
      res = Typhoeus.get(url)
      if res.success?
        return @events = JSON.load(res.body)
      end
      STDERR.puts("Error retrieving meetups:\n#{res.body}")
      return @events = []
    end

    def next_event(group_name)
      event = events(group_name).find { |e| e["status"] == "upcoming" }
      return nil if event.nil?
      Data.new(event)
    end
  end
end

def main
  group = "vienna-rb"
  meetup = Meetup::Client.new(ENV.fetch("MEETUP_API_KEY"))
  ap meetup.next_event(group)
end;main

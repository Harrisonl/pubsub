require 'rubygems'
require 'redis'
require 'json'

@redis = Redis.new(:timeout => 0)

@redis.subscribe(ARGV) do |on|
  on.message do |channel, msg|
    data = JSON.parse(msg)
    puts "[#{channel}] => #{data['ticker']} price changed by $#{data['diff']}, now trading at $#{data['price']} per share. Current Position is #{data['current_position']}."
  end
end

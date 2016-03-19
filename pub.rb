require 'redis'
require 'json'
require "net/http"
require 'open-uri'
require 'pry'

class Stock
  attr_reader :ticker, :buy_price, :quantity, :trader, :price
  attr_accessor :observers

  def initialize stock
    @ticker = stock[:ticker]
    @price = stock[:price]
    @buy_price = stock[:price]
    @quantity = stock[:quantity]
    @trader = stock[:trader]
    @observers = stock[:observers] ? stock[:observers] : []
  end

  def update_price amount
    unless @price == amount
      diff = amount - @price.to_f
      @price = amount
      notify_observers(diff)
    end
  end

  def current_position
    diff = (price * quantity) - (buy_price * quantity)
    diff >= 0 ? "+$#{diff}" : "$#{diff}"
  end

  private

  def notify_observers diff
    observers.each { |obsv| obsv.notify(self, diff) }
  end
end

class StockLookupService

  def monitor_stocks *stocks
    loop do
      stocks.each do |stock|
        uri = URI("http://dev.markitondemand.com/MODApis/Api/v2/Quote/json?symbol=#{stock.ticker}")
        response = JSON.parse(Net::HTTP.get(uri))
        stock.update_price(response['LastPrice'])
      end
      sleep 5
    end
  end
end

class StockWatcher

  def initialize redis
    @redis_server = redis
  end

  def notify stock, diff
    data = { ticker: stock.ticker, diff: diff, price: stock.price, current_position: stock.current_position}
    puts "Sending #{data}, on #{stock.trader}"
    @redis_server.publish stock.trader, data.to_json
  end
end

# Initialise the stock watchers
watcher = StockWatcher.new(Redis.new)
lookup_service = StockLookupService.new

# Create the stocks
google = Stock.new(ticker: 'GOOG', price: 20, quantity: 11, trader: 'Glen', observers: [watcher])
apple = Stock.new(ticker: 'AAPL', price: 20, quantity: 10, trader: 'Alice', observers: [watcher])
google_alice = Stock.new(ticker: 'GOOG', price: 20, quantity: 11, trader: 'Alice', observers: [watcher])
gm = Stock.new(ticker: 'GM', price: 100, quantity: 30, trader: 'Robert', observers: [watcher])

# Start the watching Process
lookup_service.monitor_stocks(google, google_alice, apple, gm)






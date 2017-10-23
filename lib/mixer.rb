require 'data_mapper'
require 'dm-types'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/json'
require 'pry'

$:.unshift File.dirname(__FILE__)
require 'jobcoin'
require 'user'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/development.db")

class Mixer
  # Jobcoin's addresses are just strings; e.g. Alice's address can be "Alice",
  # and Bob's address can be "Bob". Therefore we hardcode "Mixer" here.
  JOBCOIN_DEPOSIT_ADDRESS = 'Mixer'.freeze
end

DataMapper.finalize
DataMapper.auto_upgrade!

def json_params
  begin
    JSON.parse(request.body.read)
  rescue
    halt 400, { message: 'Invalid JSON' }.to_json
  end
end

# API Endpoints
#
post '/register' do
  content_type :json

  addresses = Array(json_params)
  user = User.new(addresses: addresses)

  if user.save
    json deposit_address: user.deposit_address
  else
    halt 400, { message: 'Invalid user params' }.to_json
  end
end

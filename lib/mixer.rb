require 'data_mapper'
require 'dm-types'
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/json'
require 'pry'

$:.unshift File.dirname(__FILE__)
require 'jobcoin'
require 'user'
require 'deposit'

rack_env = ENV.fetch('RACK_ENV', 'development')
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/#{rack_env.strip}.db")

class Mixer < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  # Jobcoin's addresses are just strings; e.g. Alice's address can be "Alice",
  # and Bob's address can be "Bob". Therefore we hardcode "Mixer" here.
  JOBCOIN_DEPOSIT_ADDRESS = 'Mixer'.freeze

  #################
  # API Endpoints #
  #################
  get '/status' do
    # TODO: maybe this endpoint can poll the mixer's
    # public deposit address...? For now just using to test
    # that RSpec is wired up correctly to these endpoints.
    json foo: 'bar'
  end

  post '/registrations' do
    content_type :json

    addresses = Array(json_params)
    user = User.new(addresses: addresses)

    if user.save
      status 201
      json sendJobcoinsTo: JOBCOIN_DEPOSIT_ADDRESS
    else
      halt 400, { message: user.humanized_errors }.to_json
    end
  end
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

require 'data_mapper'
require 'dm-types'
require 'dm-timestamps'
require 'sinatra/base'
require 'sinatra/json'
require 'pry'

rack_env = ENV.fetch('RACK_ENV', 'development')
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/#{rack_env.strip}.db")

# models
$:.unshift File.dirname(__FILE__)
Dir['models/*.rb'].each { |file| require file }

# lib files
Dir['lib/*.rb'].each { |file| require file }

# jobs needed by mixer API
require 'sidekiq'
require 'sidekiq-cron'
Dir['jobs/*.rb'].each { |file| require file }

class Mixer < Sinatra::Base
  # Jobcoin's addresses are just strings; e.g. Alice's address can be "Alice",
  # and Bob's address can be "Bob". Therefore we hardcode "Mixer" here.
  JOBCOIN_DEPOSIT_ADDRESS = 'Mixer'.freeze

  include Utils

  #################
  # API Endpoints #
  #################
  post '/registrations' do
    content_type :json

    user = User.new(json_params)
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

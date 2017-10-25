require 'data_mapper'
require 'dm-types'
require 'dm-timestamps'
require 'sinatra/base'
require 'sinatra/json'
require 'pry'

# require models
$:.unshift File.join(File.dirname(__FILE__), 'models')
require 'user'
require 'deposit'
require 'repayment'

# require lib files
$:.unshift File.join(File.dirname(__FILE__), 'jobs')
require 'poll_mixer_deposit_address_job'
require 'send_jobcoins_job'

# require lib files
$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'jobcoin'

rack_env = ENV.fetch('RACK_ENV', 'development')
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/#{rack_env.strip}.db")

class Mixer < Sinatra::Base
  # Jobcoin's addresses are just strings; e.g. Alice's address can be "Alice",
  # and Bob's address can be "Bob". Therefore we hardcode "Mixer" here.
  JOBCOIN_DEPOSIT_ADDRESS = 'Mixer'.freeze

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

def json_params
  begin
    JSON.parse(request.body.read)
  rescue
    halt 400, { message: 'Invalid JSON' }.to_json
  end
end

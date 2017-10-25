require 'rack/test'
require 'rspec'
require 'database_cleaner'

ENV['RACK_ENV'] = 'test'

require File.expand_path '../../mixer.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app() described_class end
end

RSpec.configure do |c|
  c.include RSpecMixin

  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/db/#{ENV['RACK_ENV']}.db")
  DataMapper.finalize
  DataMapper.auto_migrate!

  c.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  c.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

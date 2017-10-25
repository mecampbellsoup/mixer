$:.unshift(File.expand_path('../..', __FILE__))

require 'sidekiq'
require 'sidekiq-cron'
require 'mixer'

class Configuration
  def self.url
    ENV.fetch('REDIS_URI', 'redis://localhost:6379')
  end
end

Sidekiq.configure_server do |config|
  config.redis = { url: Configuration.url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: Configuration.url }
end

# Set the every-minute background job to poll the mixer's deposit address.
Sidekiq::Cron::Job.create(
  name: 'Poll mixer deposit address every minute for new user deposits',
  cron: '* * * * *',
  class: 'PollMixerDepositAddressJob'
)

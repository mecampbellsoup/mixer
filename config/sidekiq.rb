$:.unshift(File.expand_path('..', __FILE__))

require 'sidekiq-pro'

class Configuration
  def self.url
    ENV.fetch('REDIS_URI', 'redis://localhost:6379')
  end
end

Sidekiq.configure_server do |config|
  config.redis = { url: Configuration.url }
  config.periodic do |mgr|
    # see any crontab reference for the first argument
    # e.g. http://www.adminschoice.com/crontab-quick-reference
    mgr.register('* * * * *', PollMixerDepositAddressJob)
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: Configuration.url }
end

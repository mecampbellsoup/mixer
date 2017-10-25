require 'sidekiq'

# Start up sidekiq via
# ./bin/sidekiq -r ./jobs/send_jobcoins_job.rb
#
class SendJobcoinsJob
  include Sidekiq::Worker

  def perform(from:, to:, amount:)
    Jobcoin.transactions.create(from: from, to: to, amount: amount)
  end
end

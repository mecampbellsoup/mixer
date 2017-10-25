class SendJobcoinsJob
  include Sidekiq::Worker

  def perform(from, to, amount)
    Jobcoin.transactions.create(from: from, to: to, amount: amount.to_s)
  end
end

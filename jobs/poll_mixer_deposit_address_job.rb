class PollMixerDepositAddressJob
  def perform
    # GET /addresses/:address
    binding.pry
    # how is the transactions list ordered - by timestamp? if not we
    # can always sort it by hand
  end

  private

  def most_recent_jobcoin_deposit
    transactions = Jobcoin::Address.new(Mixer::JOBCOIN_DEPOSIT_ADDRESS).transactions
    transactions.sort { |tx| tx.fetch('timestamp') }
  end

  def most_recent_deposit
    Deposit.all(order: [ :created_at.desc ]).first
  end
end

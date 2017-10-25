class PollMixerDepositAddressJob
  include Sidekiq::Worker

  # NOTE: no retry of jobs since this job is executed
  # every minute.
  sidekiq_options retry: false

  def perform
    # We compare the hash of the most recent Jobcoin transaction
    # to the hash of our most recent Deposit record.
    most_recent = Deposit.from_transaction_hash(most_recent_jobcoin_deposit)

    # OK to compare most recent JBC digest to nil (in case of Deposit.count == 0)
    # because that means there is a deposit we need to ingest, and the next line
    # wil evaluate to `true`.
    if most_recent.digest != most_recent_deposit&.digest
      # the hashes are not equal, so we are seeing a new deposit
      most_recent.save
    end
  rescue Deposit::RECEIVED_FROM_UNREGISTERED_USER
    # no-op
    # we don't ingest deposits from unregistered users...
  end

  private

  def most_recent_jobcoin_deposit
    all_jobcoin_deposits.sort { |a, b| b['timestamp'] <=> a['timestamp'] }.first
  end

  def all_jobcoin_deposits
    # GET /addresses/:address
    Jobcoin::Address.new(Mixer::JOBCOIN_DEPOSIT_ADDRESS).transactions
  end

  def most_recent_deposit
    Deposit.all(order: [ :created_at.desc ]).first
  end
end

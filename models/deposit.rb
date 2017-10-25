require 'digest'

class Deposit
  include DataMapper::Resource

  RECEIVED_FROM_UNREGISTERED_USER = Class.new(StandardError)

  HOUSE_ACCOUNT_ADDRESS = 'MixerHouseAccount'.freeze

  property :id, Serial
  property :received_address, String
  property :sent_from_address, String
  property :amount, String
  property :digest, Text
  property :created_at, DateTime

  # Relationships
  belongs_to :user

  # Validations
  validates_presence_of :received_address, :sent_from_address, :amount

  # Hooks
  before :create, :digest
  after  :create, :transfer_deposited_coins_into_house_account
  after  :create, :schedule_repayments

  class << self
    def from_transaction_hash(hash)
      new(
        sent_from_address: hash['fromAddress'],
        received_address: hash['toAddress'],
        amount: hash['amount'],
        created_at: hash['timestamp'],
        user: find_user(hash['fromAddress'])
      )
    end

    def find_user(sent_from)
      ::User.first(name: sent_from) || raise(RECEIVED_FROM_UNREGISTERED_USER)
    end
  end

  def digest
    raise if payload.values.include?(nil)

    return @digest if @digest
    payload_json = payload.to_json
    self.digest = Digest::SHA256.digest(payload_json)
  end

  private

  def transfer_deposited_coins_into_house_account
    binding.pry
    # NOTE: `raise` if this transfer fails (it should not barring JBC API issues)
    SendJobcoinsJob.new.perform(
      from: received_address,
      to: HOUSE_ACCOUNT_ADDRESS,
      amount: amount
    ) || raise("Transfer to house account failed.")
  end

  def schedule_internal_mixing_transactions
    # NOTE: creating the repayment resources enqueues the SendJobcoinsJob
    # to return jobcoins from InternalMixerAddressN to user.addresses
    schedule = MixingSchedule.new(self)
    schedule.enqueue!
  end

  def payload
    {
      'timestamp' => created_at,
      'fromAddress' => sent_from_address,
      'toAddrress' => received_address,
      'amount' => amount
    }
  end
end

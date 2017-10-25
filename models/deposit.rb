class Deposit
  include DataMapper::Resource

  RECEIVED_FROM_UNREGISTERED_USER = Class.new(StandardError)

  property :id, Serial
  property :received_address, String
  property :sent_from_address, String
  property :amount, String
  property :digest, Text
  property :created_at, DateTime

  belongs_to :user
  has n, :repayments

  validates_presence_of :received_address, :sent_from_address, :amount

  before :create, :hash_transaction_payload

  class << self
    def from_transaction_hash(hash)
      create(
        sent_from_address: hash['fromAddress'],
        received_address: hash['toAddress'],
        amount: hash['amount'],
        created_at: hash['timestamp'],
        user: find_user(hash['fromAddress'])
      )
    end

    def find_user(sent_from)
      ::User.first(name: sent_from) || raise(DepositFromUnregisteredUser)
    end
  end

  private

  def payload
    {
      'timestamp' => created_at,
      'fromAddress' => sent_from_address,
      'toAddrress' => received_address,
      'amount' => amount
    }
  end

  def hash_transaction_payload
    require 'digest'
    payload_json = payload.to_json
    self.digest = Digest::SHA256.digest(payload_json)
  end
end

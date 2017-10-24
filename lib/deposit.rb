class Deposit
  include DataMapper::Resource

  property :id, Serial
  property :received_address, String
  property :amount, String
  property :created_at, DateTime

  belongs_to :user

  def self.from_transaction_hash(hash)
    new(
      received_address: hash['toAddress'],
      amount:           hash['amount'],
      created_at:       hash['timestamp']
    )
  end
end

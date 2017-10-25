class Repayment
  HOUSE_REPAYMENT_ADDRESSES = %w(
    InternalMixerAddress1
    InternalMixerAddress2
    InternalMixerAddress3
    InternalMixerAddress4
    InternalMixerAddress5
  ).freeze

  include DataMapper::Resource

  property :id, Serial
  property :amount, String
  property :created_at, DateTime

  belongs_to :deposit

  before :create, :transfer_coins_from_house_account

  private

  def transfer_coins_from_house_account
    # In order to persist a Repayment record against a Deposit,
    # we require that the amount being repaid must be successfully
    # transferred from one of the house repayment addresses
    # to one of the user's return addresses. We perform this job
    # immediately because its success is a condition for recording
    # this repayment of the user's deposit in our DB.
    binding.pry
    SendJobcoinsJob.perform_now(
      from: REPAYMENT_ADDRESSES.sample,
      to: deposit.user.addresses_list.sample,
      amount: amount
    )
  end
end

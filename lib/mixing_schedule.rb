require 'utils'

class Array
  def except(value)
    self - [value]
  end
end

# Every mixing schedule will perform 3 'steps', or 3
# rounds of internal transactions in order to obfuscate the
# history of the user's deposited coins.
#
# This schedule therefore relies on a predetermined sequence of
# transfers to take place.
#
# For example, Matt deposits 50 jobcoins.
# We break those 50 coins into `n` random chunks, let's call it
# 10, 20, 15, and 5 JBC chunks.
class MixingSchedule
  include ::Utils

  NUMBER_OF_INTERNAL_TRANSACTIONS = 3.freeze

  INTERNAL_CHILD_ADDRESSES = %w(
    InternalMixerAddress1
    InternalMixerAddress2
    InternalMixerAddress3
    InternalMixerAddress4
    InternalMixerAddress5
  ).freeze

  attr_reader :deposit, :chunks

  def initialize(deposit)
    @deposit = deposit
    # NOTE: break deposit amount into somewhere between 2 and 5 chunks
    @chunks = (2 .. 5).to_a.sample
  end

  def enqueue!
    # first generate the schedule of mix transfers
    # then enqueue all of them
    schedule.each do |amount, internal_address|
      SendJobcoinsJob.perform_in(20, { from: Deposit::HOUSE_ACCOUNT_ADDRESS, to: INTERNAL_CHILD_ADDRESSES[internal_address[0]], amount: amount })
      SendJobcoinsJob.perform_in(40, { from: INTERNAL_CHILD_ADDRESSES[internal_address[0]], to: INTERNAL_CHILD_ADDRESSES[internal_address[1]], amount: amount })
      SendJobcoinsJob.perform_in(60, { from: INTERNAL_CHILD_ADDRESSES[internal_address[1]], to: deposit.user.addresses_list.sample, amount: amount })
    end
  end

  private

  def increments
    # => [ 10, 20, 15, 5 ]
    correct_total = false
    until correct_total
      splits = split_into(deposit.amount.to_i, chunks)
      correct_total = true if splits.sum.to_f == deposit.amount.to_f
    end
    splits
  end

  def schedule
    # Generate a hash of incremental amounts
    # with the internal mix address to use for each amount.
    increments.zip(hops(chunks))
  end

  def hops(num)
    randomized = (0 .. num - 1).to_a.shuffle
    randomized.map { |n| [n, randomized.except(n).sample] }
  end
end

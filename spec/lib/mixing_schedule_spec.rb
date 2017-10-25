require 'spec_helper'

RSpec.describe MixingSchedule do
  let!(:user) { User.create(name: 'Matt', addresses: ['one', 'two', 'three']) }

  let(:hash) do
    {
      'timestamp' => '2017-10-23T22:31:25.150Z',
      'fromAddress' => 'Matt',
      'amount' => '10',
      'toAddress' => 'Mixer'
    }
  end

  let(:deposit) { Deposit.from_transaction_hash(hash) }
  before { deposit.save! }

  let(:mixing_schedule) { described_class.new(deposit) }

  describe "#enqueue!" do
    it 'enqueues a time-ordered series of jobcoin transaction jobs' do
      chunks = mixing_schedule.chunks
      expect(SendJobcoinsJob.jobs.size).to eq 0
      mixing_schedule.enqueue!
      expect(SendJobcoinsJob.jobs.size).to eq (3 * chunks)
    end

    it 'enqueues the correct number of jobs to return the deposited coins to the user' do
      mixing_schedule.enqueue!
      return_to_user_jobs = SendJobcoinsJob.jobs.select do |job|
          user.addresses_list.include?(job['args'][0]['to'])
      end

      to_be_returned_amount = return_to_user_jobs.reduce(0) do |accum, inc|
        accum += inc['args'][0]['amount']
        accum
      end

      expect(to_be_returned_amount).to eq deposit.amount.to_f
    end
  end
end

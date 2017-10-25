require 'spec_helper'

RSpec.describe PollMixerDepositAddressJob do
  # Eagerly persist this user so that we can setup Deposit records
  let!(:user) { User.create!(name: 'Alice', addresses: ['one', 'two', 'three']) }

  let(:jobcoin_deposit) do
    {
      'timestamp' => '2017-10-23T22:31:25.150Z',
      'fromAddress' => 'Alice',
      'toAddress' => 'Mixer',
      'amount' => '10'
    }
  end

  # Stub the request fetch the mixer's deposits
  before do
    allow_any_instance_of(Jobcoin::Address)
      .to receive(:transactions)
      .and_return([jobcoin_deposit])
  end

  describe "#perform" do
    context 'when all JBC deposits to the mixer have already been ingested' do
      let!(:seen) do
        d = Deposit.from_transaction_hash(jobcoin_deposit)
        d.tap(&:save!)
      end

      before do
        expect(compare_timestamps(seen.created_at, DateTime.parse(jobcoin_deposit['timestamp'])))
      end

      it 'does not create any additional deposit records' do
        expect { described_class.new.perform }.to_not change { ::Deposit.count }
      end
    end
  end
end

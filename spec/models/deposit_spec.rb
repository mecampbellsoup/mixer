require 'spec_helper'

RSpec.describe Deposit do
  # Deposits belong to a user
  let(:user) { User.create(name: 'Matt', addresses: ['one', 'two', 'three']) }

  let(:hash) do
    {
      'timestamp' => '2017-10-23T22:31:25.150Z',
      'fromAddress' => 'Matt',
      'amount' => '10',
      'toAddress' => 'Mixer'
    }
  end

  describe ".from_transaction_hash" do
    subject { Deposit.from_transaction_hash(hash) }

    context 'when the user cannot be found via the sent from address' do
      it 'raises an exception' do
        expect { subject }.to raise_error { Deposit::RECEIVED_FROM_UNREGISTERED_USER }
      end
    end

    context 'when the user can be found via the sent from address' do
      before { user.save }

      it 'builds a deposit with a timestamp matching the Jobcoin transaction' do
        subject
        expect(subject.created_at).to eq DateTime.parse(hash['timestamp'])
      end

      it 'writes the hashed payload with the DB record' do
        payload = subject.send(:payload)
        payload_digest = Digest::SHA256.digest(payload.to_json)

        expect(subject.digest).to eq payload_digest
      end

      it 'builds a valid deposit record' do
        expect { subject.save! }.to change { Deposit.count }.from(0).to(1)
      end
    end
  end
end

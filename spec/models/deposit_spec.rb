require 'spec_helper'

RSpec.describe Deposit do
  # Deposits belong to a user
  let(:user) { User.create(name: 'Matt', addresses: ['one', 'two', 'three']) }

  describe ".from_transaction_hash" do
    subject { Deposit.from_transaction_hash(hash) }
    let(:hash) do
      {
        'timestamp' => '2017-10-23T22:31:25.150Z',
        'fromAddress' => 'Matt',
        'amount' => '10',
        'toAddress' => 'Mixer'
      }
    end

    context 'when the user cannot be found via the sent from address' do
      it 'raises an exception' do
        expect { subject }.to raise_error { Deposit::RECEIVED_FROM_UNREGISTERED_USER }
      end
    end

    context 'when the user can be found via the sent from address' do
      before { user.save }

      it 'saves the deposit record' do
        expect { subject }.to change { Deposit.count }.from(0).to(1)
      end
    end
  end

  describe ".create" do
    let(:attributes) do
      {
        received_address: 'Mixer',
        sent_from_address: user.name,
        amount: '10'
      }
    end

    let(:deposit) { described_class.new(attributes) }
    let(:payload) { deposit.send(:payload) }
    let(:payload_digest) { Digest::SHA256.digest(payload.to_json) }

    context 'valid' do
      it 'writes the hashed payload with the DB record' do
        user.deposits << deposit
        user.save
        expect(deposit.digest).to eq payload_digest
      end
    end
  end
end

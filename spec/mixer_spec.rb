require File.expand_path '../spec_helper.rb', __FILE__

RSpec.describe ::Mixer do
  describe "POST /registrations" do
    let(:data) { { name: "Matt", addresses: addresses } }
    subject { post '/registrations', data.to_json }

    # Happy path
    context "user provides at least one re-deposit address" do
      let(:addresses) { [ 'testAddress1' ] }

      before do
        allow_any_instance_of(Jobcoin::Address).to receive(:transactions).and_return([])
      end

      let(:addresses) { ['notUsedAddress1', 'notUsedAddress2'] }

      it "creates a new user record" do
        expect { subject }.to change { ::User.count }.by(1)
      end

      it "associates the unused address(es) with the new user" do
        subject
        user = ::User.first
        expect(JSON(user.addresses)).to eq addresses
      end

      it "responds with 201 and the 'deposit to mixer' address" do
        post '/registrations', data.to_json

        expect(last_response.status).to eq 201
        expect(last_response.body).to eq({ sendJobcoinsTo: 'Mixer' }.to_json)
      end
    end
  end
end

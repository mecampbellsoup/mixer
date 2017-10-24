require File.expand_path '../spec_helper.rb', __FILE__

RSpec.describe ::Mixer do
  describe "GET /status" do
    it 'responds 200 OK' do
      get '/status'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ foo: 'bar' }.to_json)
    end
  end

  describe "POST /registrations" do
    subject { post '/registrations', addresses.to_json }

    context "user provides at least one re-deposit address" do
      let(:addresses) { [ 'testAddress1' ] }

      # Sad path
      context "the provided address has already been used" do
        # NOTE: non-empty list of transactions means the address has been used!
        before do
          allow_any_instance_of(Jobcoin::Address).to receive(:transactions).and_return(['anything'])
        end

        it "responds 400" do
          subject
          expect(last_response.status).to eq 400
          expect(last_response.body).to eq({
            message: "One or more of the provided addresses has already been used"
          }.to_json)
        end

        it "does not create a new user record" do
          expect { subject }.to_not change { ::User.count }
        end
      end

      # Happy path
      context "the provided address has not already been used" do
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
          post '/registrations', addresses.to_json, {}

          expect(last_response.status).to eq 201
          expect(last_response.body).to eq({ sendJobcoinsTo: 'Mixer' }.to_json)
        end
      end
    end
  end
end

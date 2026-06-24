require 'rails_helper'

RSpec.describe "POST /v1/user/check_status", type: :request do
  subject(:make_request) do
    post "/v1/user/check_status", params: params, headers: headers, as: :json
    response
  end

  let(:idfa)    { SecureRandom.uuid }
  let(:params)  { { idfa: idfa, rooted_device: false } }
  let(:headers) { { "CF-IPCountry" => "US" } }

  before do
    allow(REDIS).to receive(:sismember).and_return(true)

    vpn_service = instance_double(VpnCheckService,
      call: { "security" => { "vpn" => false, "tor" => false, "proxy" => false } })
    allow(VpnCheckService).to receive(:new).and_return(vpn_service)
  end

  context "with valid params" do
    it { is_expected.to have_http_status(:ok) }

    it "returns not_banned" do
      expect(JSON.parse(subject.body)).to eq("ban_status" => "not_banned")
    end

    it "creates a user" do
      expect { subject }.to change(User, :count).by(1)
    end

    it "creates an integrity log" do
      expect { subject }.to change(IntegrityLog, :count).by(1)
    end
  end

  context "when idfa is missing" do
    let(:params) { { rooted_device: false } }

    it { is_expected.to have_http_status(:bad_request) }

    it "returns error message" do
      expect(JSON.parse(subject.body)).to eq("error" => "idfa is required")
    end
  end

  context "when idfa is blank" do
    let(:params) { { idfa: "", rooted_device: false } }

    it { is_expected.to have_http_status(:bad_request) }

    it "returns error message" do
      expect(JSON.parse(subject.body)).to eq("error" => "idfa is required")
    end
  end

  context "when country is not whitelisted" do
    before do
      allow(REDIS).to receive(:sismember).with("country_whitelist", "US").and_return(false)
    end

    it "returns banned" do
      expect(JSON.parse(subject.body)).to eq("ban_status" => "banned")
    end
  end

  context "when country header is missing" do
    let(:headers) { {} }

    it "returns banned" do
      expect(JSON.parse(subject.body)).to eq("ban_status" => "banned")
    end
  end

  context "when rooted_device is true" do
    let(:params) { { idfa: idfa, rooted_device: true } }

    it "returns banned" do
      expect(JSON.parse(subject.body)).to eq("ban_status" => "banned")
    end
  end

  context "when user already exists" do
    let!(:existing_user) { create(:user, idfa: idfa) }

    it "does not create a user" do
      expect { subject }.not_to change(User, :count)
    end

    context "when ban_status is unchanged" do
      it "does not create an integrity log" do
        expect { subject }.not_to change(IntegrityLog, :count)
      end

      it "returns not_banned" do
        expect(JSON.parse(subject.body)).to eq("ban_status" => "not_banned")
      end
    end

    context "when rooted_device becomes true" do
      let(:params) { { idfa: idfa, rooted_device: true } }

      it "creates an integrity log" do
        expect { subject }.to change(IntegrityLog, :count).by(1)
      end

      it "returns banned" do
        expect(JSON.parse(subject.body)).to eq("ban_status" => "banned")
      end
    end

    context "when user is already banned" do
      let!(:existing_user) { create(:user, idfa: idfa, ban_status: :banned) }

      it "returns banned" do
        expect(JSON.parse(subject.body)).to eq("ban_status" => "banned")
      end
    end
  end
end

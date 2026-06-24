require 'rails_helper'

RSpec.describe "V1::UserChecks", type: :request do
  describe "POST /v1/user/check_status" do
    before do
      allow(REDIS).to receive(:sismember).and_return(true)

      vpn_service = instance_double(VpnCheckService, call: { "security" => { "vpn" => false, "tor" => false, "proxy" => false } })
      allow(VpnCheckService).to receive(:new).and_return(vpn_service)
    end

    let(:idfa) { SecureRandom.uuid }

    let(:request_body) do
      {
        idfa: idfa,
        rooted_device: false
      }
    end

    let(:request_headers) do
      {
        "CF-IPCountry" => "US"
      }
    end

    it "returns not_banned by default" do
      post "/v1/user/check_status", params: request_body, headers: request_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("ban_status" => "not_banned")
    end

    it "creates a user with the provided idfa" do
      expect do
        post "/v1/user/check_status", params: request_body, headers: request_headers, as: :json
      end.to change(User, :count).by(1)

      expect(User.last.idfa).to eq(request_body[:idfa])
    end

    it "creates an integrity log for a new user" do
      expect do
        post "/v1/user/check_status", params: request_body, headers: request_headers, as: :json
      end.to change(IntegrityLog, :count).by(1)

      log = IntegrityLog.last
      expect(log.idfa).to eq(request_body[:idfa])
      expect(log.ban_status).to eq("not_banned")
      expect(log.ip).to be_present
      expect(log.country).to eq("US")
      expect(log.rooted_device).to eq(false)
      expect(log.vpn).to eq(false)
      expect(log.proxy).to eq(false)
    end

    it "creates an integrity log when ban_status changes" do
      create(:user, idfa: request_body[:idfa])

      rooted_request_body = request_body.merge(rooted_device: true)

      expect do
        post "/v1/user/check_status", params: rooted_request_body, headers: request_headers, as: :json
      end.to change(IntegrityLog, :count).by(1)
    end

    it "does not create an integrity log when ban_status is unchanged" do
      create(:user, idfa: request_body[:idfa])

      expect do
        post "/v1/user/check_status", params: request_body, headers: request_headers, as: :json
      end.not_to change(IntegrityLog, :count)
    end

    it "returns banned and saves banned status when rooted_device is true" do
      rooted_request_body = request_body.merge(rooted_device: true)

      post "/v1/user/check_status", params: rooted_request_body, headers: request_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("ban_status" => "banned")
      expect(User.find_by(idfa: rooted_request_body[:idfa])&.ban_status).to eq("banned")
    end

    it "returns not_banned for an existing not_banned user" do
      existing_user = create(:user, idfa: request_body[:idfa])

      post "/v1/user/check_status", params: request_body, headers: request_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("ban_status" => "not_banned")
      expect(existing_user.reload.ban_status).to eq("not_banned")
    end

    it "returns banned for an existing banned user" do
      existing_user = create(:user, idfa: request_body[:idfa], ban_status: :banned)

      post "/v1/user/check_status", params: request_body, headers: request_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("ban_status" => "banned")
      expect(existing_user.reload.ban_status).to eq("banned")
    end

    it "returns banned when country is not in whitelist" do
      allow(REDIS).to receive(:sismember).with("country_whitelist", "US").and_return(false)

      post "/v1/user/check_status", params: request_body, headers: request_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("ban_status" => "banned")
      expect(User.find_by(idfa: request_body[:idfa])&.ban_status).to eq("banned")
    end

    it "returns banned when country header is missing" do
      post "/v1/user/check_status", params: request_body, as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("ban_status" => "banned")
    end

    it "returns 400 when idfa is missing" do
      post "/v1/user/check_status", params: { rooted_device: false }, headers: request_headers, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq("error" => "idfa is required")
    end

    it "returns 400 when idfa is blank" do
      post "/v1/user/check_status", params: { idfa: "", rooted_device: false }, headers: request_headers, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq("error" => "idfa is required")
    end
  end
end

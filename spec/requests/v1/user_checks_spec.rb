require 'rails_helper'

RSpec.describe "V1::UserChecks", type: :request do
  describe "POST /v1/user/check_status" do
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

    it "returns banned and saves banned status when rooted_device is true" do
      rooted_request_body = request_body.merge(rooted_device: true)

      post "/v1/user/check_status", params: rooted_request_body, headers: request_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("ban_status" => "banned")
      expect(User.find_by(idfa: rooted_request_body[:idfa])&.ban_status).to eq("banned")
    end

    it "returns banned for an existing banned user" do
      existing_user = User.create!(idfa: request_body[:idfa], ban_status: :banned)

      post "/v1/user/check_status", params: request_body, headers: request_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("ban_status" => "banned")
      expect(existing_user.reload.ban_status).to eq("banned")
    end
  end
end

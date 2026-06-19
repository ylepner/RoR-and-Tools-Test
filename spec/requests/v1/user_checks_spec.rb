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
  end
end

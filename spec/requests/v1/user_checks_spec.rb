require 'rails_helper'

RSpec.describe "V1::UserChecks", type: :request do
  describe "POST /v1/user/check_status" do
    it "returns not_banned by default" do
      post "/v1/user/check_status",
           params: {
             idfa: "8264148c-be95-4b2b-b260-6ee98dd53bf6",
             rooted_device: false
           }.to_json,
           headers: {
             "CONTENT_TYPE" => "application/json",
             "CF-IPCountry" => "US"
           }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("ban_status" => "not_banned")
    end
  end
end

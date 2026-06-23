require 'rails_helper'

RSpec.describe IntegrityLog, type: :model do
  describe "validations" do
    it "can create a valid record" do
      log = IntegrityLog.create!(
        idfa: SecureRandom.uuid,
        ban_status: :not_banned,
        ip: "127.0.0.1",
        country: "US",
        rooted_device: false,
        vpn: false,
        proxy: false
      )

      expect(log).to be_persisted
    end
  end
end

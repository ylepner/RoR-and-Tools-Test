require 'rails_helper'

RSpec.describe IntegrityLogger do
  describe "#call" do
    let(:user) { User.create!(idfa: SecureRandom.uuid, ban_status: :not_banned) }
    let(:ip) { "192.168.1.1" }
    let(:country) { "US" }
    let(:rooted_device) { false }
    let(:vpn) { false }
    let(:proxy) { false }

    subject(:logger_call) do
      described_class.new(
        user: user,
        ip: ip,
        country: country,
        rooted_device: rooted_device,
        vpn: vpn,
        proxy: proxy
      ).call
    end

    it "creates an IntegrityLog record" do
      expect { logger_call }.to change(IntegrityLog, :count).by(1)
    end

    it "saves all fields correctly" do
      log = logger_call

      expect(log.idfa).to eq(user.idfa)
      expect(log.ban_status).to eq("not_banned")
      expect(log.ip).to eq(ip)
      expect(log.country).to eq(country)
      expect(log.rooted_device).to eq(false)
      expect(log.vpn).to eq(false)
      expect(log.proxy).to eq(false)
    end

    context "when user is banned" do
      let(:user) { User.create!(idfa: SecureRandom.uuid, ban_status: :banned) }

      it "saves banned status" do
        log = logger_call
        expect(log.ban_status).to eq("banned")
      end
    end

    context "with banned user and vpn is true" do
      let(:user) { User.create!(idfa: SecureRandom.uuid, ban_status: :banned) }
      let(:vpn) { true }
      let(:proxy) { true }

      it "saves correct fields" do
        log = logger_call

        expect(log.ban_status).to eq("banned")
        expect(log.vpn).to eq(true)
        expect(log.proxy).to eq(true)
      end
    end
  end
end

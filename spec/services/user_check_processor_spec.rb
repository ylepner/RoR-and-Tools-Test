require 'rails_helper'

RSpec.describe UserCheckProcessor do
  describe "#call" do
    let(:idfa) { SecureRandom.uuid }
    let(:country) { "US" }
    let(:ip) { "192.168.1.1" }
    let(:rooted_device) { false }

    subject(:processor_call) do
      described_class.new(
        idfa: idfa,
        country: country,
        ip: ip,
        rooted_device: rooted_device
      ).call
    end

    before do
      allow(REDIS).to receive(:sismember).and_return(true)

      vpn_service = instance_double(VpnCheckService, call: { "security" => { "vpn" => false, "tor" => false, "proxy" => false } })
      allow(VpnCheckService).to receive(:new).and_return(vpn_service)
    end

    it "creates a new user" do
      expect { processor_call }.to change(User, :count).by(1)
    end

    it "sets ban_status to not_banned by default" do
      user = processor_call
      expect(user.ban_status).to eq("not_banned")
    end

    it "creates an integrity log for a new user" do
      expect { processor_call }.to change(IntegrityLog, :count).by(1)

      log = IntegrityLog.last
      expect(log.idfa).to eq(idfa)
      expect(log.ban_status).to eq("not_banned")
      expect(log.country).to eq(country)
      expect(log.rooted_device).to eq(false)
      expect(log.vpn).to eq(false)
      expect(log.proxy).to eq(false)
    end

    it "returns the user object" do
      expect(processor_call).to be_a(User)
      expect(processor_call.idfa).to eq(idfa)
    end

    context "when user already exists with same ban_status" do
      let!(:existing_user) { create(:user, idfa: idfa, ban_status: :not_banned) }

      it "does not create an integrity log" do
        expect { processor_call }.not_to change(IntegrityLog, :count)
      end

      it "does not change ban_status" do
        expect(processor_call.ban_status).to eq("not_banned")
      end
    end

    context "when user already exists and ban_status changes" do
      let!(:existing_user) { create(:user, idfa: idfa, ban_status: :not_banned) }
      let(:rooted_device) { true }

      it "creates an integrity log" do
        expect { processor_call }.to change(IntegrityLog, :count).by(1)
      end

      it "updates ban_status to banned" do
        expect(processor_call.reload.ban_status).to eq("banned")
      end
    end

    context "when country is not whitelisted" do
      before do
        allow(REDIS).to receive(:sismember).with("country_whitelist", country).and_return(false)
      end

      it "sets ban_status to banned" do
        expect(processor_call.ban_status).to eq("banned")
      end

      it "creates an integrity log for a new user" do
        expect { processor_call }.to change(IntegrityLog, :count).by(1)
      end
    end

    context "when vpn is detected" do
      before do
        vpn_service = instance_double(VpnCheckService, call: { "security" => { "vpn" => true, "tor" => false, "proxy" => false } })
        allow(VpnCheckService).to receive(:new).and_return(vpn_service)
      end

      it "sets ban_status to banned" do
        expect(processor_call.ban_status).to eq("banned")
      end

      it "logs vpn as true" do
        processor_call
        expect(IntegrityLog.last.vpn).to eq(true)
      end
    end

    context "when rooted_device is true" do
      let(:rooted_device) { true }

      it "sets ban_status to banned" do
        expect(processor_call.ban_status).to eq("banned")
      end
    end

    context "when vpn API returns unexpected response" do
      before do
        vpn_service = instance_double(VpnCheckService, call: nil)
        allow(VpnCheckService).to receive(:new).and_return(vpn_service)
      end

      it "sets ban_status to not_banned" do
        expect(processor_call.ban_status).to eq("not_banned")
      end

      it "logs vpn and proxy as false" do
        processor_call
        log = IntegrityLog.last
        expect(log.vpn).to eq(false)
        expect(log.proxy).to eq(false)
      end
    end
  end
end

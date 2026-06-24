require 'rails_helper'

RSpec.describe UserCheckProcessor do
  describe "#call" do
    let(:idfa) { SecureRandom.uuid }
    let(:country) { "US" }
    let(:ip) { "192.168.1.1" }
    let(:rooted_device) { false }

    subject(:call) do
      described_class.new(
        idfa: idfa, country: country, ip: ip, rooted_device: rooted_device
      ).call
    end

    before do
      allow(REDIS).to receive(:sismember).and_return(true)

      vpn_service = instance_double(VpnCheckService,
        call: { "security" => { "vpn" => false, "tor" => false, "proxy" => false } })
      allow(VpnCheckService).to receive(:new).and_return(vpn_service)
    end

    context "with default params" do
      it { expect { subject }.to change(User, :count).by(1) }
      it { expect { subject }.to change(IntegrityLog, :count).by(1) }
      it { is_expected.to be_a(User) }
      it { is_expected.to have_attributes(idfa: idfa) }
      it { is_expected.to have_attributes(ban_status: "not_banned") }
    end

    context "when user already exists" do
      let!(:existing_user) { create(:user, idfa: idfa, ban_status: :not_banned) }

      it { expect { subject }.not_to change(User, :count) }

      context "with same ban_status" do
        it { expect { subject }.not_to change(IntegrityLog, :count) }
        it { is_expected.to have_attributes(ban_status: "not_banned") }
      end

      context "when ban_status changes" do
        let(:rooted_device) { true }

        it { expect { subject }.to change(IntegrityLog, :count).by(1) }
        it { is_expected.to have_attributes(ban_status: "banned") }
      end
    end

    context "when country is not whitelisted" do
      before do
        allow(REDIS).to receive(:sismember).with("country_whitelist", country).and_return(false)
      end

      it { is_expected.to have_attributes(ban_status: "banned") }
      it { expect { subject }.to change(IntegrityLog, :count).by(1) }
    end

    context "when vpn is detected" do
      before do
        vpn_service = instance_double(VpnCheckService,
          call: { "security" => { "vpn" => true, "tor" => false, "proxy" => false } })
        allow(VpnCheckService).to receive(:new).and_return(vpn_service)
      end

      it { is_expected.to have_attributes(ban_status: "banned") }

      it "logs vpn as true" do
        subject
        expect(IntegrityLog.last.vpn).to eq(true)
      end
    end

    context "when rooted_device is true" do
      let(:rooted_device) { true }

      it { is_expected.to have_attributes(ban_status: "banned") }
    end

    context "when vpn API returns unexpected response" do
      before do
        vpn_service = instance_double(VpnCheckService, call: nil)
        allow(VpnCheckService).to receive(:new).and_return(vpn_service)
      end

      it { is_expected.to have_attributes(ban_status: "not_banned") }

      it "logs vpn and proxy as false" do
        subject
        log = IntegrityLog.last
        expect(log.vpn).to eq(false)
        expect(log.proxy).to eq(false)
      end
    end
  end
end

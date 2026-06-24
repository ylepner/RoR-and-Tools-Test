require 'rails_helper'

RSpec.describe IntegrityLogger do
  after do
    IntegrityLogger.config do |c|
      c.adapter = IntegrityLogActiveRecordAdapter.new
    end
  end

  describe "#call" do
    let(:user) { create(:user) }
    let(:ip) { "192.168.1.1" }
    let(:country) { "US" }
    let(:rooted_device) { false }
    let(:vpn) { false }
    let(:proxy) { false }

    subject(:log) do
      described_class.new(
        user: user, ip: ip, country: country,
        rooted_device: rooted_device, vpn: vpn, proxy: proxy
      ).call
    end

    context "with default params" do
      it { expect { subject }.to change(IntegrityLog, :count).by(1) }

      it { is_expected.to have_attributes(idfa: user.idfa) }
      it { is_expected.to have_attributes(ban_status: "not_banned") }
      it { is_expected.to have_attributes(ip: ip) }
      it { is_expected.to have_attributes(country: country) }
      it { is_expected.to have_attributes(rooted_device: false) }
      it { is_expected.to have_attributes(vpn: false) }
      it { is_expected.to have_attributes(proxy: false) }
    end

    context "when user is banned" do
      let(:user) { create(:user, ban_status: :banned) }

      it { is_expected.to have_attributes(ban_status: "banned") }
    end

    context "with banned user and vpn is true" do
      let(:user) { create(:user, ban_status: :banned) }
      let(:vpn) { true }
      let(:proxy) { true }

      it { is_expected.to have_attributes(ban_status: "banned") }
      it { is_expected.to have_attributes(vpn: true) }
      it { is_expected.to have_attributes(proxy: true) }
    end

    context "with a custom adapter" do
      let(:custom_adapter) { instance_double(IntegrityLogActiveRecordAdapter) }

      before do
        IntegrityLogger.config { |c| c.adapter = custom_adapter }
      end

      it "delegates create to the adapter" do
        expect(custom_adapter).to receive(:create).with(
          idfa: user.idfa, ban_status: "not_banned",
          ip: ip, country: country,
          rooted_device: rooted_device, vpn: vpn, proxy: proxy
        )

        subject
      end
    end
  end
end

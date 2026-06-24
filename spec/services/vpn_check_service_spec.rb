require 'rails_helper'

RSpec.describe VpnCheckService do
  describe "#call" do
    subject(:result) { described_class.new(ip).call }

    let(:ip) { "1.2.3.4" }

    context "with valid API response" do
      before do
        allow_any_instance_of(described_class).to receive(:fetch_from_api)
          .and_return("security" => { "vpn" => false, "tor" => false, "proxy" => false })
      end

      it { is_expected.to eq("security" => { "vpn" => false, "tor" => false, "proxy" => false }) }
    end

    context "when API fails" do
      before do
        allow_any_instance_of(described_class).to receive(:fetch_from_api).and_raise(StandardError)
      end

      it { is_expected.to eq("security" => { "vpn" => false, "tor" => false, "proxy" => false }) }
    end

    context "caching" do
      around do |example|
        original_cache = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        example.run
        Rails.cache = original_cache
      end

      context "with same IP" do
        it "calls API once" do
          expect_any_instance_of(described_class).to receive(:fetch_from_api).once
            .and_return("security" => { "vpn" => false, "tor" => false, "proxy" => false })

          described_class.new(ip).call
          described_class.new(ip).call
        end
      end

      it "expires after 24 hours" do
        expect(Rails.cache).to receive(:fetch).with("vpn:#{ip}", expires_in: 24.hours)
        subject
      end
    end
  end
end

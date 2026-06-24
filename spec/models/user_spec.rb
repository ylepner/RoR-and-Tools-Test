require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  it { is_expected.to be_valid }

  context "when idfa is nil" do
    subject { build(:user, idfa: nil) }

    it { is_expected.not_to be_valid }
  end

  context "when idfa is duplicate" do
    let(:idfa) { SecureRandom.uuid }

    before { create(:user, idfa: idfa) }

    subject { build(:user, idfa: idfa) }

    it { is_expected.not_to be_valid }
  end

  context "when ban_status is nil" do
    subject { build(:user, ban_status: nil) }

    it { is_expected.not_to be_valid }
  end
end

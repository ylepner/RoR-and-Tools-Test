require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with idfa" do
      user = described_class.new(idfa: SecureRandom.uuid)

      expect(user).to be_valid
    end

    it "requires idfa" do
      user = described_class.new(idfa: nil)

      expect(user).not_to be_valid
      expect(user.errors[:idfa]).to include("can't be blank")
    end

    it "requires unique idfa" do
      idfa = SecureRandom.uuid
      described_class.create!(idfa: idfa)

      duplicate = described_class.new(idfa: idfa)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:idfa]).to include("has already been taken")
    end
  end

  describe "defaults" do
    it "sets ban_status to not_banned by default" do
      user = described_class.create!(idfa: SecureRandom.uuid)

      expect(user.ban_status).to eq("not_banned")
    end
  end
end

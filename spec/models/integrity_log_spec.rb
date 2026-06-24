require 'rails_helper'

RSpec.describe IntegrityLog, type: :model do
  describe "validations" do
    it "can create a valid record" do
      log = build(:integrity_log)
      expect(log).to be_valid
    end
  end
end

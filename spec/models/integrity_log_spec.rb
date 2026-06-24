require 'rails_helper'

RSpec.describe IntegrityLog, type: :model do
  subject(:log) { build(:integrity_log) }

  it { is_expected.to be_valid }
end

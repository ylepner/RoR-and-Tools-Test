class User < ApplicationRecord
  enum :ban_status, { not_banned: 0, banned: 1 }

  validates :idfa, presence: true, uniqueness: true
  validates :ban_status, presence: true
end
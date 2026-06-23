class IntegrityLog < ApplicationRecord
  enum :ban_status, { not_banned: 0, banned: 1 }
end

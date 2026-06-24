FactoryBot.define do
  factory :integrity_log do
    idfa { SecureRandom.uuid }
    ban_status { :not_banned }
    ip { "127.0.0.1" }
    rooted_device { false }
    country { "US" }
    vpn { false }
    proxy { false }
  end
end

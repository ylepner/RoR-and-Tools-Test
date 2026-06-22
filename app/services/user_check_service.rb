class UserCheckService
  def initialize(user:, country:, rooted_device:)
    @user = user
    @country = country
    @rooted_device = ActiveModel::Type::Boolean.new.cast(rooted_device)
  end

  def call
    return :banned if @user&.banned?
    # Ban the user if the CF-IPCountry header value is not in the Redis country whitelist
    return :banned unless country_allowed?
    # Rooted Device Check: Ban if rooted_device is true.

    return :banned if @rooted_device

    :not_banned
  end

  private

  def country_allowed?
    country = @country.to_s.strip.upcase
    return false if country.empty?

    REDIS.sismember("country_whitelist", country)
  end
end

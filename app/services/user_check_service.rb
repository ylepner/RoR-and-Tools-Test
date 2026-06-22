class UserCheckService
  def initialize(user:, country:, ip:, rooted_device:)
    @user = user
    @country = country
    @ip = ip
    @rooted_device = ActiveModel::Type::Boolean.new.cast(rooted_device)
  end

  def call
    return :banned if @user&.banned?
    return :banned unless country_allowed?
    return :banned if @rooted_device
    return :banned if vpn_or_tor?

    :not_banned
  end

  private

  def country_allowed?
    country = @country.to_s.strip.upcase
    return false if country.empty?

    REDIS.sismember("country_whitelist", country)
  end

  def vpn_or_tor?
    result = VpnCheckService.new(@ip).call
    result["security"]["vpn"] || result["security"]["tor"]
  end
end

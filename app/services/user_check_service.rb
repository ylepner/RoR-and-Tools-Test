class UserCheckService
  def initialize(user:, country:, rooted_device:, vpn:)
    @user = user
    @country = country
    @rooted_device = ActiveModel::Type::Boolean.new.cast(rooted_device)
    @vpn = vpn
  end

  def call
    return :banned if @user&.banned?
    return :banned unless country_allowed?
    return :banned if @rooted_device
    return :banned if @vpn

    :not_banned
  end

  private

  def country_allowed?
    CountryWhitelistStore.new.allowed?(@country)
  end
end

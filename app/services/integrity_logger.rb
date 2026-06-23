class IntegrityLogger
  def initialize(user:, ip:, country:, rooted_device:, vpn:, proxy:)
    @user = user
    @ip = ip
    @country = country
    @rooted_device = rooted_device
    @vpn = vpn
    @proxy = proxy
  end

  def call
    IntegrityLog.create!(
      idfa: @user.idfa,
      ban_status: @user.ban_status,
      ip: @ip,
      country: @country,
      proxy: @proxy,
      vpn: @vpn,
      rooted_device: @rooted_device
    )
  end
end

class IntegrityLogger
  def initialize(user:, ip:, country:, rooted_device:, vpn:, proxy:, adapter: IntegrityLogAdapter.new)
    @user = user
    @adapter = adapter
    @attrs = {
      ip: ip, country: country, rooted_device: rooted_device,
      vpn: vpn, proxy: proxy
    }
  end

  def call
    @adapter.create(
      idfa: @user.idfa, ban_status: @user.ban_status, **@attrs
    )
  end
end

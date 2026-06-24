class IntegrityLogger
  class Configuration
    attr_accessor :adapter
  end

  class << self
    def config
      yield @config ||= Configuration.new
    end

    def adapter
      @config&.adapter || IntegrityLogActiveRecordAdapter.new
    end
  end

  def initialize(user:, ip:, country:, rooted_device:, vpn:, proxy:)
    @user = user
    @attrs = {
      ip: ip, country: country, rooted_device: rooted_device,
      vpn: vpn, proxy: proxy
    }
  end

  def call
    self.class.adapter.create(
      idfa: @user.idfa, ban_status: @user.ban_status, **@attrs
    )
  end
end

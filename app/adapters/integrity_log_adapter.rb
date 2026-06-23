class IntegrityLogAdapter
  def create(idfa:, ban_status:, ip:, country:, rooted_device:, vpn:, proxy:)
    IntegrityLog.create!(
      idfa: idfa,
      ban_status: ban_status,
      ip: ip,
      country: country,
      rooted_device: rooted_device,
      vpn: vpn,
      proxy: proxy
    )
  end
end

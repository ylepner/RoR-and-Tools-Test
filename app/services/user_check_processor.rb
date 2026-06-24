class UserCheckProcessor
  def initialize(idfa:, country:, ip:, rooted_device:)
    @idfa = idfa
    @country = country
    @ip = ip
    @rooted_device = rooted_device
  end

  def call
    resolve_user
    check_vpn
    determine_ban_status
    save_user
    log_if_needed
    @user
  end

  private

  def resolve_user
    @user = User.find_or_initialize_by(idfa: @idfa)
    @was_new = @user.new_record?
    @old_status = @user.ban_status
  end

  def check_vpn
    vpn_result = VpnCheckService.new(@ip).call
    security = vpn_result.to_h["security"] || {}
    @vpn = !!(security["vpn"] || security["tor"])
    @proxy = !!security["proxy"]
  end

  def determine_ban_status
    result = UserCheckService.new(
      user: @user,
      country: @country,
      rooted_device: @rooted_device,
      vpn: @vpn
    ).call

    @user.ban_status = result
  end

  def save_user
    @user.save!
  end

  def log_if_needed
    return unless @was_new || @old_status != @user.ban_status

    IntegrityLogger.new(
      user: @user,
      ip: @ip,
      country: @country,
      rooted_device: @rooted_device,
      vpn: @vpn,
      proxy: @proxy
    ).call
  end
end

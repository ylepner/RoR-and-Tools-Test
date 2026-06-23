class V1::UserChecksController < ApplicationController
  def create
    user = User.find_by(idfa: check_params[:idfa])
    was_new = user.nil?

    user ||= User.new(idfa: check_params[:idfa])

    old_status = user&.ban_status

    ip = request.headers["CF-Connecting-IP"] || request.remote_ip
    country = request.headers["CF-IPCountry"]
    rooted_device = check_params[:rooted_device]

    vpn_result = VpnCheckService.new(ip).call
    vpn = vpn_result["security"]["vpn"] || vpn_result["security"]["tor"]
    proxy = vpn_result["security"]["proxy"]

    service = UserCheckService.new(
      user: user,
      country: country,
      rooted_device: rooted_device,
      vpn: vpn
    )

    result = service.call

    user.update!(ban_status: result)

    if was_new || old_status != user.ban_status
      IntegrityLogger.new(
        user: user,
        ip: ip,
        country: country,
        rooted_device: rooted_device,
        vpn: vpn,
        proxy: proxy
      ).call
    end

    render json: { ban_status: user.ban_status }
  end

  private

  def check_params
    params.permit(:idfa, :rooted_device)
  end
end

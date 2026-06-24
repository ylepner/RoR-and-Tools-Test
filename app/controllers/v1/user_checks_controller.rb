class V1::UserChecksController < ApplicationController
  def check_status
    idfa = check_params[:idfa].to_s.strip
    return render(json: { error: "idfa is required" }, status: :bad_request) if idfa.empty?

    user = UserCheckProcessor.new(
      idfa: idfa,
      country: request.headers["CF-IPCountry"],
      ip: request.headers["CF-Connecting-IP"] || request.remote_ip,
      rooted_device: check_params[:rooted_device]
    ).call

    render json: { ban_status: user.ban_status }
  end

  private

  def check_params
    params.permit(:idfa, :rooted_device)
  end
end

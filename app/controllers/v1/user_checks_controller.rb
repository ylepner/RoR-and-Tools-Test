class V1::UserChecksController < ApplicationController
  def create
    user = User.find_or_initialize_by(idfa: check_params[:idfa])

    service = UserCheckService.new(
      user: user,
      country: request.headers["CF-IPCountry"],
      rooted_device: check_params[:rooted_device]
    )

    result = service.call
    user.ban_status = result
    user.save!

    render json: { ban_status: user.ban_status }
  end

  private

  def check_params
    params.permit(:idfa, :rooted_device)
  end
end

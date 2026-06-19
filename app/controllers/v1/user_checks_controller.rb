class V1::UserChecksController < ApplicationController
  def create
    user = User.find_or_initialize_by(idfa: check_params[:idfa])

    if user.persisted? && user.banned?
      render json: { ban_status: "banned" }
      return
    end

    result = run_checks(rooted_device: check_params[:rooted_device])
    user.ban_status = result
    user.save!

    render json: { ban_status: user.ban_status }
  end

  private

  def check_params
    params.permit(:idfa, :rooted_device)
  end

  def run_checks(rooted_device:)
    return "banned" if ActiveModel::Type::Boolean.new.cast(rooted_device)

    "not_banned"
  end
end

class V1::UserChecksController < ApplicationController
  def create
    User.find_or_create_by!(idfa: params[:idfa])
    render json: { ban_status: "not_banned" }
  end
end

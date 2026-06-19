class V1::UserChecksController < ApplicationController
  def create
    render json: { ban_status: "not_banned" }
  end
end

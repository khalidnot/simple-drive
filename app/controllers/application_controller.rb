class ApplicationController < ActionController::API
  before_action :authenticate_request!

  attr_reader :current_user

  private

  def authenticate_request!
    header = request.headers["Authorization"]
    token = header&.split(" ")&.last

    if token.blank?
      render json: { error: "Missing token" }, status: :unauthorized
      return
    end

    decoded = Authentication::JwtService.decode(token)
    @current_user = User.find(decoded[:user_id])
  rescue JWT::ExpiredSignature
    render json: { error: "Token expired" }, status: :unauthorized
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
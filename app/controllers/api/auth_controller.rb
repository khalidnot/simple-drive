class Api::AuthController < ApplicationController
    skip_before_action :authenticate_request!, only: [:register, :login]
  def register
    user = User.new(user_params)

    if user.save
      render json: {
        message: "User created successfully",
        user: {
          id: user.id,
          email: user.email
        }
      }, status: :created
    else
      render json: {
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      token = Authentication::JwtService.encode({ user_id: user.id }, 30.minutes.from_now)

      render json: {
        message: "Login successful",
        token: token,
        token_type: "Bearer",
        expires_in: 30.minutes.to_i,
        user: {
          id: user.id,
          email: user.email
        }
      }, status: :ok
    else
      render json: {
        error: "Invalid email or password"
      }, status: :unauthorized
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
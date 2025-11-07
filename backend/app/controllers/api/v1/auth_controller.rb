module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: [:register, :login]

      # POST /api/v1/auth/register
      def register
        user = User.new(register_params)

        if user.save
          token = generate_jwt(user)
          render json: {
            message: 'Registration successful',
            user: user_response(user),
            token: token
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/auth/login
      def login
        user = User.find_by(email: login_params[:email])

        if user&.valid_password?(login_params[:password])
          token = generate_jwt(user)
          render json: {
            message: 'Login successful',
            user: user_response(user),
            token: token
          }, status: :ok
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      # DELETE /api/v1/auth/logout
      def logout
        # JWT will be revoked by devise-jwt automatically
        render json: { message: 'Logged out successfully' }, status: :ok
      end

      # GET /api/v1/auth/me
      def me
        render json: { user: user_response(current_user) }, status: :ok
      end

      private

      def register_params
        params.require(:user).permit(:email, :password, :password_confirmation, :name, :phone, :role)
      end

      def login_params
        params.require(:user).permit(:email, :password)
      end

      def generate_jwt(user)
        Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
      end

      def user_response(user)
        {
          id: user.id,
          email: user.email,
          name: user.name,
          phone: user.phone,
          role: user.role,
          active: user.active,
          created_at: user.created_at
        }
      end
    end
  end
end

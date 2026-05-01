class Api::V1::AuthController < Api::V1::BaseController
    skip_before_action :authenticate_user, only: [:login, :signup]

    def login
        user_params = params.require(:user).permit(:email, :password)
        user = User.find_by(email: user_params[:email])
        if user&.authenticate(user_params[:password])
            token = user.generate_jwt
            render_success({ token: token, user: { id: user.id, email: user.email, role: user.role } }, 'Login successful')
        else
            render_unauthorized('Invalid credentials')
        end
    end

    def signup
        user = User.new(user_params)
        if user.save
            token = user.generate_jwt
            render_success({ token: token, user: { id: user.id, email: user.email, role: user.role } }, 'User created successfully', :created)
        else
            render_error('Validation failed', :unprocessable_content, user.errors.full_messages)
        end
    end

    def logout
        token = request.headers['Authorization']&.split(' ')&.last
        if token
            decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
            exp = Time.at(decoded['exp'])
            BlocklistedToken.create!(token: token, exp: exp)
            render_success({}, 'Logged out successfully')
        else
            render_unauthorized('No token provided')
        end
        rescue JWT::DecodeError
            render_unauthorized('Invalid token')
        end

    private

    def user_params
        params.require(:user).permit(:name, :email, :password)
    end
end
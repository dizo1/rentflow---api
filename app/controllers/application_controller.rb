class ValidationError < StandardError
  attr_reader :details

  def initialize(message = nil, details: nil)
    super(message)
    @details = details
  end
end

class ApplicationController < ActionController::API
    before_action :authenticate_user

    rescue_from JWT::ExpiredSignature, with: :token_expired
    rescue_from JWT::DecodeError, with: :invalid_token
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from ActionController::ParameterMissing, with: :missing_parameter
    rescue_from StandardError, with: :internal_server_error

    private

    def authenticate_user
        token = request.headers['Authorization']&.split(' ')&.last
        if token
            begin
                decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
                @current_user = User.find(decoded['user_id'])
            rescue JWT::ExpiredSignature
                render json: { success: false, error: 'Token expired' }, status: :unauthorized
            rescue JWT::DecodeError
                render json: { success: false, error: 'Invalid token' }, status: :unauthorized
            end
        else
            render json: { success: false, error: 'Missing token' }, status: :unauthorized
        end
    end

    def current_user
        @current_user
    end

    def admin_user?
        current_user&.admin?
    end

    # Exception handlers
    def token_expired
        render json: { success: false, error: 'Token expired' }, status: :unauthorized
    end

    def invalid_token
        render json: { success: false, error: 'Invalid token' }, status: :unauthorized
    end

    def record_not_found
        render json: { success: false, error: 'Resource not found' }, status: :not_found
    end

    def missing_parameter(exception)
        render json: { success: false, error: "Missing required parameter: #{exception.param}" }, status: :bad_request
    end

    def internal_server_error(exception)
        Rails.logger.error("[Internal Server Error] #{exception.class}: #{exception.message}")
        Rails.logger.error(exception.backtrace.join("\n"))
        render json: { success: false, error: 'Internal server error' }, status: :internal_server_error
    end
end

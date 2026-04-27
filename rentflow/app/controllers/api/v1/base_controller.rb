class Api::V1::BaseController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid, with: :validation_error
  rescue_from ::ValidationError, with: :validation_error_handler

  private

  def render_success(data = nil, message = nil, status = :ok)
    response = { success: true }
    response[:data] = data if !data.nil? && (data.present? || data.is_a?(Array))
    response[:message] = message if message.present?
    render json: response, status: status
  end

  def render_error(message, status = :unprocessable_content, details = nil)
    response = { success: false, error: message }
    response[:details] = details if details.present?
    render json: response, status: status
  end

  def render_unauthorized(message = 'Unauthorized')
    render_error(message, :unauthorized)
  end

  def render_forbidden(message = 'Forbidden')
    render_error(message, :forbidden)
  end

  def render_not_found(message = 'Not found')
    render_error(message, :not_found)
  end

  # Exception handlers
  def validation_error(exception)
    render_error('Validation failed', :unprocessable_content, exception.record.errors.full_messages)
  end

  def validation_error_handler(exception)
    render_error(exception.message, :unprocessable_content, exception.details)
  end
end
class Api::V1::PaymentsController < Api::V1::BaseController
  before_action :authenticate_user

  # POST /api/v1/payments/upgrade
  def upgrade
    plan = params[:plan]&.to_sym
    return render_error("Invalid plan", :bad_request) unless valid_plan?(plan)

    result = PaymentService.new(current_user, plan).process_payment

    if result[:success]
      render_success(
        { plan: plan, payment: result[:payment].as_json(only: [ :id, :amount, :reference, :paid_at ]) },
        result[:message]
      )
    else
      render_error(result[:error], :unprocessable_content)
    end
  end

  # GET /api/v1/payments
  def index
    payments = current_user.payments.order(created_at: :desc)
    render_success(
      payments.as_json(only: [ :id, :amount, :plan, :status, :reference, :paid_at ])
    )
  end

  # POST /api/v1/payments/webhook
  def webhook
    # For now, just log the incoming request
    Rails.logger.info("[WEBHOOK] Received payment webhook: #{params.inspect}")
    head :ok
  end

  private

  def valid_plan?(plan)
    %i[basic pro].include?(plan)
  end
end

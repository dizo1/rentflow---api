class Api::V1::PaymentsController < Api::V1::BaseController
  before_action :authenticate_user
  before_action :set_payment, only: [:show]
  before_action :authorize_payment, only: [:show]

  # GET /api/v1/payments
  def index
    payments = current_user.payments.order(created_at: :desc)
    render_success(
      payments.as_json(only: [:id, :amount, :plan, :status, :reference, :paid_at, :created_at]),
      'Payments retrieved successfully'
    )
  end

  # GET /api/v1/payments/:id
  def show
    render_success(
      @payment.as_json(
        only: [:id, :user_id, :amount, :plan, :status, :reference, :payment_method, :paid_at, :created_at, :updated_at]
      ),
      'Payment retrieved successfully'
    )
  end

  # POST /api/v1/payments/upgrade
  def upgrade
    plan = params[:plan]&.to_sym
    return render_error('Invalid plan', :bad_request) unless valid_plan?(plan)

    result = PaymentService.new(current_user, plan).process_payment

    if result[:success]
      render_success(
        { plan: plan, payment: result[:payment].as_json(only: [:id, :amount, :reference, :paid_at]) },
        result[:message]
      )
    else
      render_error(result[:error], :unprocessable_content)
    end
  end

  # POST /api/v1/payments/webhook
  def webhook
    Rails.logger.info("[WEBHOOK] Received payment webhook: #{params.inspect}")
    head :ok
  end

  private

  def set_payment
    @payment = Payment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('Payment not found')
  end

  def authorize_payment
    render_forbidden('Unauthorized') unless current_user.admin? || @payment.user_id == current_user.id
  end

  def valid_plan?(plan)
    %i[basic pro].include?(plan)
  end
end
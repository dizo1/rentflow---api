class PaymentService
  PLAN_PRICES = {
    basic: 59000.00,
    pro: 199000.00
  }.freeze

  def initialize(user, plan)
    @user = user
    @plan = plan.to_sym
  end

  def process_payment
    return { success: false, error: "Invalid plan" } unless valid_plan?

    amount = PLAN_PRICES[@plan]

    payment = Payment.create!(
      user: @user,
      amount: amount,
      plan: @plan,
      status: :successful,
      reference: generate_reference,
      paid_at: Time.current
    )

    SubscriptionService.new.upgrade_plan(@user, @plan)

    { success: true, payment: payment, message: "Payment successful. Plan upgraded to #{@plan}." }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.message }
  end

  private

  def valid_plan?
    PLAN_PRICES.key?(@plan)
  end

  def generate_reference
    loop do
      ref = "RF-#{SecureRandom.hex(6).upcase}"
      break ref unless Payment.exists?(reference: ref)
    end
  end
end

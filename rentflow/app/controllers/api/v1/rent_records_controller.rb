class Api::V1::RentRecordsController < Api::V1::BaseController
  before_action :require_admin, only: [:index, :create]
  before_action :set_unit, only: [:index, :create]
  before_action :set_rent_record, only: [:show, :update, :destroy]
  before_action :authorize_rent_record, only: [:show, :update, :destroy]

  # GET /api/v1/units/:unit_id/rent_records
  def index
    rent_records = if admin_user?
      @unit.rent_records.includes(:tenant)
    elsif @unit.property.user_id == current_user.id
      @unit.rent_records.includes(:tenant)
    else
      render_forbidden('Unauthorized')
      return
    end

    render_success(
      rent_records.as_json(
        only: [:id, :unit_id, :tenant_id, :amount_due, :amount_paid, :balance, :due_date, :status, :month, :year, :paid_at, :created_at, :updated_at]
      ),
      'Rent records retrieved successfully'
    )
  end

  # GET /api/v1/rent_records/:id
  def show
    render_success(
      @rent_record.as_json(
        only: [:id, :unit_id, :tenant_id, :amount_due, :amount_paid, :balance, :due_date, :status, :month, :year, :paid_at, :created_at, :updated_at],
        methods: [:tenant_full_name, :tenant_phone]
      ),
      'Rent record retrieved successfully'
    )
  end

  # POST /api/v1/units/:unit_id/rent_records
  def create
    rent_record = @unit.rent_records.build(rent_record_params)
    # Auto-associate tenant from unit if not provided
    rent_record.tenant ||= @unit.tenant

    if rent_record.save
      render_success(
        rent_record.as_json(
          only: [:id, :unit_id, :tenant_id, :amount_due, :amount_paid, :balance, :due_date, :status, :month, :year, :paid_at, :created_at, :updated_at],
          methods: [:tenant_full_name, :tenant_phone]
        ),
        'Rent record created successfully',
        :created
      )
    else
      render_error('Validation failed', :unprocessable_content, rent_record.errors.full_messages)
    end
  end

  # PUT/PATCH /api/v1/rent_records/:id
  # Accepts either amount_paid (to add a payment) or direct field updates
  def update
    # Special handling for payment updates
    if payment_update_params.key?(:amount_paid)
      payment_amount = payment_update_params[:amount_paid].to_f
      current_paid = @rent_record.amount_paid.to_f
      new_total_paid = current_paid + payment_amount

      @rent_record.amount_paid = new_total_paid
      @rent_record.balance = @rent_record.amount_due - new_total_paid

      # Auto-determine status based on financial state
      if @rent_record.balance <= 0
        @rent_record.status = 'paid'
        @rent_record.paid_at ||= Time.current
      elsif payment_amount > 0 && @rent_record.balance > 0
        @rent_record.status = 'partial'
      end

      # Check for overdue
      if @rent_record.due_date.past? && @rent_record.balance > 0
        @rent_record.status = 'overdue'
      end
    else
      # Standard update (allow direct status changes like 'waived')
      @rent_record.assign_attributes(rent_record_params)
    end

    if @rent_record.save
      render_success(
        @rent_record.as_json(
          only: [:id, :unit_id, :tenant_id, :amount_due, :amount_paid, :balance, :due_date, :status, :month, :year, :paid_at, :created_at, :updated_at],
          methods: [:tenant_full_name, :tenant_phone]
        ),
        'Rent record updated successfully'
      )
    else
      render_error('Update failed', :unprocessable_content, @rent_record.errors.full_messages)
    end
  end

  # DELETE /api/v1/rent_records/:id
  def destroy
    @rent_record.destroy
    render_success(nil, 'Rent record deleted successfully', :no_content)
  end

  # POST /api/v1/rent_records/:id/record_payment
  # Explicit endpoint for recording a payment (clearer intent)
  def record_payment
    payment_amount = params[:payment_amount].to_f
    if payment_amount <= 0
      return render_error('Payment amount must be greater than zero', :unprocessable_content)
    end

    current_paid = @rent_record.amount_paid.to_f
    new_total_paid = current_paid + payment_amount

    @rent_record.amount_paid = new_total_paid
    @rent_record.balance = @rent_record.amount_due - new_total_paid

    if @rent_record.balance <= 0
      @rent_record.status = 'paid'
      @rent_record.paid_at ||= Time.current
    else
      @rent_record.status = 'partial'
    end

    if @rent_record.due_date.past? && @rent_record.balance > 0
      @rent_record.status = 'overdue'
    end

    if @rent_record.save
      render_success(
        @rent_record.as_json(
          only: [:id, :unit_id, :tenant_id, :amount_due, :amount_paid, :balance, :due_date, :status, :month, :year, :paid_at],
          methods: [:tenant_full_name, :tenant_phone]
        ),
        'Payment recorded successfully'
      )
    else
      render_error('Payment recording failed', :unprocessable_content, @rent_record.errors.full_messages)
    end
  end

  private

  def set_unit
    if params[:unit_id]
      if admin_user?
        @unit = Unit.find(params[:unit_id])
      else
        @unit = Unit.joins(:property).where(properties: { user_id: current_user.id }).find(params[:unit_id])
      end
    elsif params[:id] && !@rent_record
      set_rent_record
      @unit = @rent_record.unit
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found('Unit not found')
  end

  def set_rent_record
    @rent_record = RentRecord.includes(:tenant, unit: :property).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('Rent record not found')
  end

  def authorize_rent_record
    record = @rent_record || (@unit&.rent_records&.find(params[:id]))
    return unless record

    unless admin_user? || record.unit.property.user_id == current_user.id
      render_forbidden('Unauthorized')
    end
  end

  def rent_record_params
    params.require(:rent_record).permit(
      :tenant_id,
      :amount_due,
      :amount_paid,
      :balance,
      :due_date,
      :status,
      :month,
      :year
    )
  end

  def payment_update_params
    params.permit(:payment_amount)
  end

  def require_admin
    render_forbidden('Admin access required') unless admin_user?
  end
end

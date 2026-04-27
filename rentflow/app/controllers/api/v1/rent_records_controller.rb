class Api::V1::RentRecordsController < Api::V1::BaseController
  before_action :require_admin, only: [:index, :create]
  before_action :set_unit, only: [:index, :create]
  before_action :set_rent_record, only: [:show, :update, :destroy]
  before_action :authorize_rent_record, only: [:show, :update, :destroy]

  # GET /api/v1/units/:unit_id/rent_records
  def index
    rent_records = if admin_user?
      @unit.rent_records
    elsif @unit.property.user_id == current_user.id
      @unit.rent_records
    else
      render_forbidden('Unauthorized')
      return
    end
    render_success(
      rent_records.as_json(only: [:id, :unit_id, :amount_due, :amount_paid, :balance, :due_date, :status, :month, :year, :paid_at]),
      'Rent records retrieved successfully'
    )
  end

  # GET /api/v1/rent_records/:id
  def show
    render_success(
      @rent_record.as_json(only: [:id, :unit_id, :amount_due, :amount_paid, :balance, :due_date, :status, :month, :year, :paid_at]),
      'Rent record retrieved successfully'
    )
  end

  # POST /api/v1/units/:unit_id/rent_records
  def create
    rent_record = @unit.rent_records.build(rent_record_params)
    if rent_record.save
      render_success(
        rent_record.as_json(only: [:id, :unit_id, :amount_due, :amount_paid, :balance, :due_date, :status, :month, :year, :paid_at]),
        'Rent record created successfully',
        :created
      )
    else
      render_error('Validation failed', :unprocessable_content, rent_record.errors.full_messages)
    end
  end

  # PUT /api/v1/rent_records/:id
  def update
    if @rent_record.update(rent_record_params)
      render_success(
        @rent_record.as_json(only: [:id, :unit_id, :amount_due, :amount_paid, :balance, :due_date, :status, :month, :year, :paid_at]),
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
    @rent_record = RentRecord.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('Rent record not found')
  end

  def authorize_rent_record
    render_forbidden('Unauthorized') unless current_user.admin? || @rent_record.unit.property.user_id == current_user.id
  end

  def rent_record_params
    params.require(:rent_record).permit(:amount_due, :amount_paid, :balance, :due_date, :status, :month, :year)
  end

  def require_admin
    render_forbidden('Admin access required') unless admin_user?
  end
end
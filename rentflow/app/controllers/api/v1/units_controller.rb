class Api::V1::UnitsController < Api::V1::BaseController
  before_action :require_admin, only: [:index, :create]
  before_action :set_unit, only: [:show, :update, :destroy]
  before_action :authorize_unit, only: [:show, :update, :destroy]
  before_action :set_property, only: [:index, :create]

  # GET /api/v1/properties/:property_id/units
  def index
    units = if admin_user?
      @property.units
    elsif @property.user_id == current_user.id
      @property.units
    else
      render_forbidden('Unauthorized')
      return
    end
    render_success(units.as_json(only: [:id, :property_id, :unit_number, :rent_amount, :deposit_amount, :occupancy_status, :tenant_name, :tenant_phone]), 'Units retrieved successfully')
  end

  # POST /api/v1/properties/:property_id/units
  def create
    unit = @property.units.build(unit_params)
    if unit.save
      render_success(unit.as_json(only: [:id, :property_id, :unit_number, :rent_amount, :deposit_amount, :occupancy_status, :tenant_name, :tenant_phone]), 'Unit created successfully', :created)
    else
      render_error('Validation failed', :unprocessable_content, unit.errors.full_messages)
    end
  end

  # GET /api/v1/units/:id
  def show
    render_success(@unit.as_json(only: [:id, :property_id, :unit_number, :rent_amount, :deposit_amount, :occupancy_status, :tenant_name, :tenant_phone]), 'Unit retrieved successfully')
  end

  # PUT /api/v1/units/:id
  def update
    if @unit.update(unit_params)
      render_success(@unit.as_json(only: [:id, :property_id, :unit_number, :rent_amount, :deposit_amount, :occupancy_status, :tenant_name, :tenant_phone]), 'Unit updated successfully')
    else
      render_error('Update failed', :unprocessable_content, @unit.errors.full_messages)
    end
  end

  # DELETE /api/v1/units/:id
  def destroy
    @unit.destroy
    render_success(nil, 'Unit deleted successfully', :no_content)
  end

  private

  def set_property
    if admin_user?
      @property = Property.find(params[:property_id])
    else
      @property = Property.where(user_id: current_user.id).find(params[:property_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found('Property not found')
  end

  def set_unit
    @unit = Unit.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('Unit not found')
  end

  def require_admin
    render_forbidden('Admin access required') unless admin_user?
  end

  def authorize_unit
    render_forbidden('Unauthorized') unless current_user.admin? || @unit.property.user_id == current_user.id
  end

  def unit_params
    params.require(:unit).permit(:property_id, :unit_number, :rent_amount, :deposit_amount, :occupancy_status, :tenant_name, :tenant_phone)
  end
end
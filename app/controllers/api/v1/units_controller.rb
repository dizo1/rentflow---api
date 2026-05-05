class Api::V1::UnitsController < Api::V1::BaseController
  before_action :set_unit, only: [:show, :update, :destroy]
  before_action :authorize_unit, only: [:show, :update, :destroy]
  before_action :set_property, only: [:index, :create]

  # GET /api/v1/units/vacant
  def vacant
    units = if admin_user?
      Unit.where(occupancy_status: 'vacant').includes(:property)
    else
      Unit.joins(:property)
          .where(properties: { user_id: current_user.id })
          .where(occupancy_status: 'vacant')
          .includes(:property)
    end

    render_success(
      units.map do |unit|
        {
          id: unit.id,
          unit_number: unit.unit_number,
          rent_amount: unit.rent_amount,
          deposit_amount: unit.deposit_amount,
          occupancy_status: unit.occupancy_status,
          property: {
            id: unit.property.id,
            name: unit.property.name,
            address: unit.property.address
          }
        }
      end,
      "#{units.count} vacant unit(s) found"
    )
  end

  # GET /api/v1/properties/:property_id/units
  def index
    units = if admin_user?
      @property.units
    else
      @property.units
    end
    render_success(
      units.as_json(
        only: [:id, :property_id, :unit_number, :rent_amount, :deposit_amount, :occupancy_status],
        methods: [:tenant_name, :tenant_phone]
      ),
      'Units retrieved successfully'
    )
  end

  # POST /api/v1/properties/:property_id/units
  def create
    unless PlanAccessService.can_create_unit?(current_user)
      return render_error('Unit limit reached. Upgrade your plan.', :forbidden)
    end
    unit = @property.units.build(unit_params)
    if unit.save
      render_success(
        unit.as_json(
          only: [:id, :property_id, :unit_number, :rent_amount, :deposit_amount, :occupancy_status],
          methods: [:tenant_name, :tenant_phone]
        ),
        'Unit created successfully',
        :created
      )
    else
      render_error('Validation failed', :unprocessable_content, unit.errors.full_messages)
    end
  end

  # GET /api/v1/units/:id
  def show
    render_success(
      @unit.as_json(
        only: [:id, :property_id, :unit_number, :rent_amount, :deposit_amount, :occupancy_status],
        methods: [:tenant_name, :tenant_phone]
      ),
      'Unit retrieved successfully'
    )
  end

  # PUT/PATCH /api/v1/units/:id
  def update
    if @unit.update(unit_params)
      render_success(
        @unit.as_json(
          only: [:id, :property_id, :unit_number, :rent_amount, :deposit_amount, :occupancy_status],
          methods: [:tenant_name, :tenant_phone]
        ),
        'Unit updated successfully'
      )
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
    @property = if admin_user?
      Property.find(params[:property_id])
    else
      Property.where(user_id: current_user.id).find(params[:property_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found('Property not found')
  end

  def set_unit
    @unit = Unit.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('Unit not found')
  end

  def authorize_unit
    render_forbidden('Unauthorized') unless current_user.admin? || @unit.property.user_id == current_user.id
  end

  def unit_params
    params.require(:unit).permit(:unit_number, :rent_amount, :deposit_amount, :occupancy_status)
  end
end
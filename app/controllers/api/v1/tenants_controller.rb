class Api::V1::TenantsController < Api::V1::BaseController
  before_action :set_tenant, only: [:show, :update, :destroy, :assign]
  before_action :set_unit, only: [:show_by_unit, :create_for_unit, :assign]
  before_action :authorize_tenant, only: [:show, :update, :destroy, :assign]

  # GET /api/v1/tenants
  def index
    tenants = if admin_user?
      Tenant.all
    else
      Tenant.joins(unit: :property).where(properties: { user_id: current_user.id })
    end

    render_success(
      tenants.as_json(only: tenant_fields),
      'Tenants retrieved successfully'
    )
  end

  # GET /api/v1/tenants/:id
  def show
    render_success(
      @tenant.as_json(only: tenant_fields),
      'Tenant retrieved successfully'
    )
  end

  # POST /api/v1/tenants — standalone creation without unit
  def create
    tenant = Tenant.new(tenant_params)
    if tenant.save
      render_success(
        tenant.as_json(only: tenant_fields),
        'Tenant created successfully',
        :created
      )
    else
      render_error('Validation failed', :unprocessable_content, tenant.errors.full_messages)
    end
  end

  # GET /api/v1/units/:unit_id/tenant
  def show_by_unit
    tenant = @unit.tenant
    if tenant
      render_success(
        tenant.as_json(only: tenant_fields),
        'Tenant retrieved successfully'
      )
    else
      render_not_found('No tenant found for this unit')
    end
  end

  # POST /api/v1/units/:unit_id/tenant — create and assign to unit
  def create_for_unit
    if @unit.tenant
      return render_error('Unit already has a tenant', :conflict)
    end

    tenant = @unit.build_tenant(tenant_params)
    if tenant.save
      @unit.update(occupancy_status: 'occupied')
      render_success(
        tenant.as_json(only: tenant_fields),
        'Tenant created and assigned successfully',
        :created
      )
    else
      render_error('Validation failed', :unprocessable_content, tenant.errors.full_messages)
    end
  end

  # PATCH /api/v1/tenants/:id/assign — assign existing tenant to a unit
  def assign
    unit = if admin_user?
      Unit.find(params[:unit_id])
    else
      Unit.joins(:property).where(properties: { user_id: current_user.id }).find(params[:unit_id])
    end

    if unit.tenant
      return render_error('Unit already has a tenant', :conflict)
    end

    if @tenant.update(unit_id: unit.id, status: 'active')
      unit.update(occupancy_status: 'occupied')
      render_success(
        @tenant.as_json(only: tenant_fields),
        'Tenant assigned to unit successfully'
      )
    else
      render_error('Assignment failed', :unprocessable_content, @tenant.errors.full_messages)
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found('Unit not found')
  end

  # PUT/PATCH /api/v1/tenants/:id
  def update
    if @tenant.update(tenant_params)
      render_success(
        @tenant.as_json(only: tenant_fields),
        'Tenant updated successfully'
      )
    else
      render_error('Update failed', :unprocessable_content, @tenant.errors.full_messages)
    end
  end

  # DELETE /api/v1/tenants/:id
  def destroy
    @tenant.destroy
    render_success(nil, 'Tenant deleted successfully', :no_content)
  end

  private

  def set_unit
    @unit = if admin_user?
      Unit.find(params[:unit_id])
    else
      Unit.joins(:property).where(properties: { user_id: current_user.id }).find(params[:unit_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found('Unit not found')
  end

  def set_tenant
    @tenant = Tenant.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('Tenant not found')
  end

  def authorize_tenant
    return if admin_user?
    return if @tenant.unit.present? && @tenant.unit.property.user_id == current_user.id
    render_forbidden('Unauthorized')
  end

  def tenant_fields
    [:id, :unit_id, :full_name, :phone, :email, :national_id,
     :move_in_date, :lease_start, :lease_end, :status, :emergency_contact, :created_at, :updated_at]
  end

  def tenant_params
    params.require(:tenant).permit(
      :full_name, :phone, :email, :national_id,
      :move_in_date, :lease_start, :lease_end,
      :status, :emergency_contact
    )
  end
end
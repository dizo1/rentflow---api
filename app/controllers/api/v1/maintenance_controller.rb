class Api::V1::MaintenanceController < Api::V1::BaseController
  before_action :set_property, only: [:index, :create]
  before_action :set_maintenance_log, only: [:show, :update, :resolve, :destroy]
  before_action :authorize_maintenance_access, only: [:index, :create]
  before_action :authorize_maintenance_log, only: [:show, :update, :resolve, :destroy]

  # GET /api/v1/maintenance/properties/:property_id
  # List all maintenance logs for a specific property
  # GET /api/v1/maintenance/properties/:property_id
  # List all maintenance logs for a specific property
  def index
    maintenance_logs = MaintenanceLog.joins(unit: :property).where(units: { property_id: @property.id })
    maintenance_logs = apply_filters(maintenance_logs)
    return if performed?

    total_count = maintenance_logs.count
    render_success(
      {
        maintenance_logs: maintenance_logs.as_json(
          only: [:id, :title, :description, :cost, :status, :priority, :reported_date, :resolved_at, :assigned_to, :notes, :created_at, :updated_at]
        ),
        total_count: total_count,
        pending_count: maintenance_logs.where(status: 'pending').count,
        in_progress_count: maintenance_logs.where(status: 'in_progress').count,
        resolved_count: maintenance_logs.where(status: 'resolved').count
      },
      "Found #{total_count} maintenance #{total_count == 1 ? 'log' : 'logs'}",
      :ok
    )
  end

  # GET /api/v1/maintenance/:id
  # View one maintenance issue
  def show
    render_success(maintenance_log_json(@maintenance_log), 'Maintenance log retrieved successfully')
  end

  # POST /api/v1/maintenance/properties/:property_id/units/:unit_id
  # Create a repair request (maintenance log)
  def create
    unit = @property.units.find(params[:unit_id])
    authorize_unit_access(unit)

    maintenance_log = unit.maintenance_logs.build(maintenance_log_params)
    maintenance_log.status = 'pending' # Always start as pending

    if maintenance_log.save
      render_success(
        maintenance_log_json(maintenance_log),
        'Maintenance request created successfully',
        :created
      )
    else
      render_error('Failed to create maintenance request', :unprocessable_content, maintenance_log.errors.full_messages)
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found('Unit not found')
  end

  # PUT /api/v1/maintenance/:id
  # Update maintenance status and details
  def update
    if @maintenance_log.update(maintenance_log_params)
      render_success(
        maintenance_log_json(@maintenance_log),
        'Maintenance log updated successfully'
      )
    else
      render_error('Failed to update maintenance log', :unprocessable_content, @maintenance_log.errors.full_messages)
    end
  end

  # PATCH /api/v1/maintenance/:id/resolve
  # Mark maintenance as resolved
  def resolve
    if @maintenance_log.update(status: 'resolved')
      render_success(
        maintenance_log_json(@maintenance_log),
        'Maintenance request marked as resolved'
      )
    else
      render_error('Failed to resolve maintenance request', :unprocessable_content, @maintenance_log.errors.full_messages)
    end
  end

  # DELETE /api/v1/maintenance/:id
  # Delete maintenance log if necessary
  def destroy
    if @maintenance_log.destroy
      render_success(nil, 'Maintenance log deleted successfully', :no_content)
    else
      render_error('Failed to delete maintenance log', :unprocessable_content)
    end
  end

  # GET /api/v1/maintenance/dashboard
  # Get maintenance dashboard data
  def dashboard
    if admin_user?
      properties = Property.all
    else
      properties = Property.where(user_id: current_user.id)
    end

    property_ids = properties.pluck(:id)

    dashboard_data = {
      total_properties: properties.count,
      total_maintenance_logs: MaintenanceLog.joins(unit: :property).where(properties: { id: property_ids }).count,
      pending_requests: MaintenanceLog.joins(unit: :property).where(properties: { id: property_ids }, status: 'pending').count,
      in_progress_requests: MaintenanceLog.joins(unit: :property).where(properties: { id: property_ids }, status: 'in_progress').count,
      resolved_requests: MaintenanceLog.joins(unit: :property).where(properties: { id: property_ids }, status: 'resolved').count,
      recent_logs: MaintenanceLog.joins(unit: :property)
        .where(properties: { id: property_ids })
        .where(created_at: 30.days.ago..Time.current)
        .order(created_at: :desc)
        .limit(10)
        .map { |log| maintenance_log_json(log) }
    }

    render_success(dashboard_data, 'Maintenance dashboard data retrieved successfully')
  end

  private

  def set_property
    if params[:property_id]
      if admin_user?
        @property = Property.find(params[:property_id])
      else
        @property = Property.where(user_id: current_user.id).find(params[:property_id])
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found('Property not found')
  end

  def set_maintenance_log
    @maintenance_log = MaintenanceLog.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('Maintenance log not found')
  end

  def authorize_maintenance_access
    return if admin_user?
    return if @property && @property.user_id == current_user.id

    render_forbidden('You do not have permission to access maintenance logs for this property')
  end

  def authorize_maintenance_log
    render_forbidden('You do not have permission to access this maintenance log') unless admin_user? || @maintenance_log.unit.property.user_id == current_user.id
  end

  def authorize_unit_access(unit)
    render_forbidden('You do not have permission to create maintenance logs for this unit') unless admin_user? || unit.property.user_id == current_user.id
  end

  def maintenance_log_params
    params.require(:maintenance_log).permit(
      :title,
      :description,
      :cost,
      :status,
      :priority,
      :reported_date,
      :assigned_to,
      :notes
    )
  end

  def maintenance_log_json(log)
    {
      id: log.id,
      title: log.title,
      description: log.description,
      cost: log.cost,
      status: log.status,
      priority: log.priority,
      reported_date: log.reported_date,
      resolved_at: log.resolved_at,
      assigned_to: log.assigned_to,
      notes: log.notes,
      created_at: log.created_at,
      updated_at: log.updated_at,
      unit: {
        id: log.unit.id,
        unit_number: log.unit.unit_number,
        property: {
          id: log.unit.property.id,
          name: log.unit.property.name
        }
      }
    }
  end

  def apply_filters(maintenance_logs)
    return maintenance_logs unless params[:status].present?

    status = params[:status]
    valid_statuses = MaintenanceLog.statuses.keys

    unless valid_statuses.include?(status)
      render_error("Invalid status. Must be one of: #{valid_statuses.join(', ')}", :bad_request)
      return MaintenanceLog.none
    end

    maintenance_logs.where(status: status)
  end
end
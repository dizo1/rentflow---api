class Api::V1::MaintenanceController < Api::V1::BaseController
  before_action :set_property, only: [:index]
  before_action :set_maintenance_log, only: [:show, :update, :resolve, :destroy]
  before_action :authorize_maintenance_log, only: [:show, :update, :resolve, :destroy]

  # GET /api/v1/maintenance
  # GET /api/v1/maintenance/properties/:property_id
  def index
    maintenance_logs = if admin_user?
      if @property
        MaintenanceLog.joins(unit: :property).where(units: { property_id: @property.id })
      else
        MaintenanceLog.joins(unit: :property)
      end
    else
      if @property
        MaintenanceLog.joins(unit: :property).where(properties: { id: @property.id, user_id: current_user.id })
      else
        MaintenanceLog.joins(unit: :property).where(properties: { user_id: current_user.id })
      end
    end

    maintenance_logs = apply_filters(maintenance_logs)
    return if performed?

    total_count = maintenance_logs.count

    render_success(
      {
        maintenance_logs: maintenance_logs.map { |log| maintenance_log_json(log) },
        total_count: total_count,
        pending_count: maintenance_logs.where(status: 'pending').count,
        in_progress_count: maintenance_logs.where(status: 'in_progress').count,
        resolved_count: maintenance_logs.where(status: 'resolved').count
      },
      "Found #{total_count} maintenance #{total_count == 1 ? 'log' : 'logs'}"
    )
  end

  # GET /api/v1/maintenance/:id
  def show
    render_success(maintenance_log_json(@maintenance_log), 'Maintenance log retrieved successfully')
  end

  # POST /api/v1/maintenance
  def create
    unit = if admin_user?
      Unit.find(params[:unit_id])
    else
      Unit.joins(:property).where(properties: { user_id: current_user.id }).find(params[:unit_id])
    end

    maintenance_log = unit.maintenance_logs.build(maintenance_log_params)
    maintenance_log.status = 'pending'

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

  # PUT/PATCH /api/v1/maintenance/:id
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
  def resolve
    if @maintenance_log.status == 'resolved'
      return render_error('Already resolved', :unprocessable_content)
    end

    if @maintenance_log.mark_resolved!
      render_success(
        maintenance_log_json(@maintenance_log),
        'Maintenance request marked as resolved'
      )
    else
      render_error('Failed to resolve maintenance request', :unprocessable_content, @maintenance_log.errors.full_messages)
    end
  end

  # DELETE /api/v1/maintenance/:id
  def destroy
    @maintenance_log.destroy
    render_success(nil, 'Maintenance log deleted successfully', :no_content)
  end

  # GET /api/v1/maintenance/dashboard
  def dashboard
    properties = if admin_user?
      Property.all
    else
      Property.where(user_id: current_user.id)
    end

    property_ids = properties.pluck(:id)
    all_logs = MaintenanceLog.joins(unit: :property).where(properties: { id: property_ids })

    render_success(
      {
        total_properties: properties.count,
        total_maintenance_logs: all_logs.count,
        pending_requests: all_logs.where(status: 'pending').count,
        in_progress_requests: all_logs.where(status: 'in_progress').count,
        resolved_requests: all_logs.where(status: 'resolved').count,
        recent_logs: all_logs.order(created_at: :desc).limit(10).map { |log| maintenance_log_json(log) }
      },
      'Maintenance dashboard data retrieved successfully'
    )
  end

  private

  def set_property
    return unless params[:property_id]
    @property = if admin_user?
      Property.find(params[:property_id])
    else
      Property.where(user_id: current_user.id).find(params[:property_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found('Property not found')
  end

  def set_maintenance_log
    @maintenance_log = MaintenanceLog.includes(unit: :property).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('Maintenance log not found')
  end

  def authorize_maintenance_log
    render_forbidden('Unauthorized') unless admin_user? || @maintenance_log.unit.property.user_id == current_user.id
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
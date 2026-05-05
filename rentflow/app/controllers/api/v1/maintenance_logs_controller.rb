class Api::V1::MaintenanceLogsController < Api::V1::BaseController
  before_action :set_unit, only: [:index, :create]
  before_action :set_maintenance_log, only: [:show, :update, :destroy, :resolve]
  before_action :authorize_maintenance_log, only: [:show, :update, :destroy, :resolve]

  # GET /api/v1/units/:unit_id/maintenance_logs
  def index
    maintenance_logs = @unit.maintenance_logs

    render_success(
      maintenance_logs.as_json(
        only: [:id, :unit_id, :title, :description, :cost, :status, :priority, :reported_date, :resolved_at, :assigned_to, :notes, :created_at, :updated_at]
      ),
      'Maintenance logs retrieved successfully'
    )
  end

  # GET /api/v1/maintenance_logs/:id
  def show
    render_success(
      @maintenance_log.as_json(
        only: [:id, :unit_id, :title, :description, :cost, :status, :priority, :reported_date, :resolved_at, :assigned_to, :notes, :created_at, :updated_at]
      ),
      'Maintenance log retrieved successfully'
    )
  end

  # POST /api/v1/units/:unit_id/maintenance_logs
  def create
    maintenance_log = @unit.maintenance_logs.build(maintenance_log_params)
    if maintenance_log.save
      render_success(
        maintenance_log.as_json(
          only: [:id, :unit_id, :title, :description, :cost, :status, :priority, :reported_date, :resolved_at, :assigned_to, :notes, :created_at, :updated_at]
        ),
        'Maintenance log created successfully',
        :created
      )
    else
      render_error('Validation failed', :unprocessable_content, maintenance_log.errors.full_messages)
    end
  end

  # PUT/PATCH /api/v1/maintenance_logs/:id
  def update
    if @maintenance_log.update(maintenance_log_params)
      render_success(
        @maintenance_log.as_json(
          only: [:id, :unit_id, :title, :description, :cost, :status, :priority, :reported_date, :resolved_at, :assigned_to, :notes, :created_at, :updated_at]
        ),
        'Maintenance log updated successfully'
      )
    else
      render_error('Update failed', :unprocessable_content, @maintenance_log.errors.full_messages)
    end
  end

  # DELETE /api/v1/maintenance_logs/:id
  def destroy
    @maintenance_log.destroy
    render_success(nil, 'Maintenance log deleted successfully', :no_content)
  end

  # PATCH /api/v1/maintenance_logs/:id/resolve
  # Convenience endpoint to mark maintenance as resolved
  def resolve
    if @maintenance_log.status == 'resolved'
      return render_error('Already resolved', :unprocessable_content)
    end

    if @maintenance_log.mark_resolved!
      render_success(
        @maintenance_log.as_json(only: [:id, :status, :resolved_at]),
        'Maintenance marked as resolved'
      )
    else
      render_error('Failed to resolve', :unprocessable_content, @maintenance_log.errors.full_messages)
    end
  end

  private

  def set_unit
    if admin_user?
      @unit = Unit.find(params[:unit_id])
    else
      @unit = Unit.joins(:property).where(properties: { user_id: current_user.id }).find(params[:unit_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found('Unit not found')
  end

  def set_maintenance_log
    @maintenance_log = MaintenanceLog.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('Maintenance log not found')
  end

  def authorize_maintenance_log
    render_forbidden('Unauthorized') unless current_user.admin? || @maintenance_log.unit.property.user_id == current_user.id
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
end

class Api::V1::MaintenanceLogsController < Api::V1::BaseController
  before_action :set_unit, only: [:index, :create]
  before_action :set_maintenance_log, only: [:show, :update, :destroy]
  before_action :authorize_maintenance_log, only: [:show, :update, :destroy]

  # GET /api/v1/units/:unit_id/maintenance_logs
  def index
    maintenance_logs = @unit.maintenance_logs.includes(:unit)
    render_success(
      maintenance_logs.as_json(
        only: [:id, :unit_id, :title, :description, :cost, :status, :resolved_at],
        include: {
          unit: { only: [:id, :unit_number] }
        }
      ),
      'Maintenance logs retrieved successfully'
    )
  end

  # GET /api/v1/maintenance_logs/:id
  def show
    render_success(
      @maintenance_log.as_json(
        only: [:id, :unit_id, :title, :description, :cost, :status, :resolved_at],
        include: {
          unit: { only: [:id, :unit_number, :property_id] }
        }
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
          only: [:id, :unit_id, :title, :description, :cost, :status, :resolved_at],
          include: {
            unit: { only: [:id, :unit_number] }
          }
        ),
        'Maintenance log created successfully',
        :created
      )
    else
      render_error('Validation failed', :unprocessable_content, maintenance_log.errors.full_messages)
    end
  end

  # PUT /api/v1/maintenance_logs/:id
  def update
    if @maintenance_log.update(maintenance_log_params)
      render_success(
        @maintenance_log.as_json(
          only: [:id, :unit_id, :title, :description, :cost, :status, :resolved_at],
          include: {
            unit: { only: [:id, :unit_number] }
          }
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

  private

  def set_unit
    if params[:unit_id]
      if admin_user?
        @unit = Unit.find(params[:unit_id])
      else
        @unit = Unit.joins(:property).where(properties: { user_id: current_user.id }).find(params[:unit_id])
      end
    elsif params[:id] && !@maintenance_log
      set_maintenance_log
      @unit = @maintenance_log.unit
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
    params.require(:maintenance_log).permit(:title, :description, :cost, :status)
  end
end
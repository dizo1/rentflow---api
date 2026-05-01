class Api::V1::RemindersController < Api::V1::BaseController
  before_action :authenticate_user
  before_action :set_reminder, only: [ :show, :update, :destroy ]

  # GET /api/v1/reminders
  def index
    # Only show reminders for the current user's properties
    reminders = Reminder.for_user(current_user.id)
    render_success(reminders)
  end

  # GET /api/v1/reminders/:id
  def show
    # Ensure the reminder belongs to the current user
    if @reminder.unit.property.user_id == current_user.id
      render_success(@reminder)
    else
      render_not_found
    end
  end

  # POST /api/v1/reminders
  def create
    # For creating a reminder, we need to ensure that the tenant and unit belong to the current user.
    # We'll find the tenant and unit by the provided IDs and check ownership.
    tenant = Tenant.find_by(id: reminder_params[:tenant_id])
    unit = Unit.find_by(id: reminder_params[:unit_id])

    if tenant && unit && unit.property.user_id == current_user.id && tenant.unit_id == unit.id
      @reminder = Reminder.new(reminder_params)
      if @reminder.save
        render_success(@reminder, "Reminder created successfully", :created)
      else
        render_error(@reminder.errors.full_messages.join(", "), :unprocessable_content)
      end
    else
      render_not_found
    end
  end

  # PATCH/PUT /api/v1/reminders/:id
  def update
    # Ensure the reminder belongs to the current user
    if @reminder.unit.property.user_id == current_user.id
      if @reminder.update(reminder_params)
        render_success(@reminder, "Reminder updated successfully")
      else
        render_error(@reminder.errors.full_messages.join(", "), :unprocessable_content)
      end
    else
      render_not_found
    end
  end

  # DELETE /api/v1/reminders/:id
  def destroy
    # Ensure the reminder belongs to the current user
    if @reminder.unit.property.user_id == current_user.id
      @reminder.destroy
      render_success(nil, "Reminder deleted successfully")
    else
      render_not_found
    end
  end

  private

  def set_reminder
    @reminder = Reminder.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  def reminder_params
    params.require(:reminder).permit(
      :tenant_id, :unit_id, :rent_record_id, :maintenance_log_id,
      :reminder_type, :message, :channel, :status, :scheduled_for,
      :sent_at, :failed_at, :failure_reason
    )
  end
end

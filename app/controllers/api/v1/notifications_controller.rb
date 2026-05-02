class Api::V1::NotificationsController < Api::V1::BaseController
  before_action :authenticate_user
  before_action :set_notification, only: [:show, :update, :destroy, :read, :unread]
  before_action :authorize_notification, only: [:show, :update, :destroy, :read, :unread]

  # GET /api/v1/notifications
  def index
    notifications = Notification.where(user_id: current_user.id)
    render_success(
      notifications.as_json(only: [:id, :title, :message, :notification_type, :read_status, :created_at, :updated_at]),
      'Notifications retrieved successfully'
    )
  end

  # GET /api/v1/notifications/:id
  def show
    render_success(
      @notification.as_json(only: [:id, :title, :message, :notification_type, :read_status, :created_at, :updated_at]),
      'Notification retrieved successfully'
    )
  end

  # POST /api/v1/notifications
  def create
    notification = Notification.new(notification_params.merge(user_id: current_user.id))
    if notification.save
      render_success(
        notification.as_json(only: [:id, :title, :message, :notification_type, :read_status, :created_at, :updated_at]),
        'Notification created successfully',
        :created
      )
    else
      render_error('Validation failed', :unprocessable_content, notification.errors.full_messages)
    end
  end

  # PATCH/PUT /api/v1/notifications/:id
  def update
    if @notification.update(notification_params)
      render_success(
        @notification.as_json(only: [:id, :title, :message, :notification_type, :read_status, :created_at, :updated_at]),
        'Notification updated successfully'
      )
    else
      render_error('Update failed', :unprocessable_content, @notification.errors.full_messages)
    end
  end

  # DELETE /api/v1/notifications/:id
  def destroy
    @notification.destroy
    render_success(nil, 'Notification deleted successfully')
  end

  # PATCH /api/v1/notifications/:id/read
  def read
    @notification.update!(read_status: true)
    render_success(
      @notification.as_json(only: [:id, :read_status]),
      'Notification marked as read'
    )
  end

  # PATCH /api/v1/notifications/:id/unread
  def unread
    @notification.update!(read_status: false)
    render_success(
      @notification.as_json(only: [:id, :read_status]),
      'Notification marked as unread'
    )
  end

  # PATCH /api/v1/notifications/read_all
  def read_all
    Notification.where(user_id: current_user.id).update_all(read_status: true)
    render_success(nil, 'All notifications marked as read')
  end

  private

  def set_notification
    @notification = Notification.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('Notification not found')
  end

  def authorize_notification
    render_forbidden('Unauthorized') unless @notification.user_id == current_user.id
  end

  def notification_params
    params.require(:notification).permit(:title, :message, :notification_type, :read_status)
  end
end
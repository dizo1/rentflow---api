class Api::V1::NotificationsController < Api::V1::BaseController
  before_action :authenticate_user
  before_action :set_notification, only: [ :show, :update, :destroy, :read, :unread ]

  # GET /api/v1/notifications
  def index
    # Only show notifications for the current user
    notifications = Notification.where(user_id: current_user.id)
    render_success(notifications)
  end

  # GET /api/v1/notifications/:id
  def show
    # Ensure the notification belongs to the current user
    if @notification.user_id == current_user.id
      render_success(@notification)
    else
      render_not_found
    end
  end

  # POST /api/v1/notifications
  def create
    # For creating a notification, we set the user_id to current_user
    @notification = Notification.new(notification_params.merge(user_id: current_user.id))
    if @notification.save
      render_success(@notification, "Notification created successfully", :created)
    else
      render_error(@notification.errors.full_messages.join(", "), :unprocessable_content)
    end
  end

  # PATCH/PUT /api/v1/notifications/:id
  def update
    # Ensure the notification belongs to the current user
    if @notification.user_id == current_user.id
      if @notification.update(notification_params)
        render_success(@notification, "Notification updated successfully")
      else
        render_error(@notification.errors.full_messages.join(", "), :unprocessable_content)
      end
    else
      render_not_found
    end
  end

  # DELETE /api/v1/notifications/:id
  def destroy
    # Ensure the notification belongs to the current user
    if @notification.user_id == current_user.id
      @notification.destroy
      render_success(nil, "Notification deleted successfully")
    else
      render_not_found
    end
  end

  # PATCH /api/v1/notifications/:id/read
  def read
    # Ensure the notification belongs to the current user
    if @notification.user_id == current_user.id
      @notification.update!(read_status: true)
      render_success(@notification, "Notification marked as read")
    else
      render_not_found
    end
  end

  # PATCH /api/v1/notifications/:id/unread
  def unread
    # Ensure the notification belongs to the current user
    if @notification.user_id == current_user.id
      @notification.update!(read_status: false)
      render_success(@notification, "Notification marked as unread")
    else
      render_not_found
    end
  end

  private

  def set_notification
    @notification = Notification.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  def notification_params
    params.require(:notification).permit(:title, :message, :notification_type, :read_status)
  end
end

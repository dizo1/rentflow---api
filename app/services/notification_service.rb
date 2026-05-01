class NotificationService
  def initialize(user)
    @user = user
  end

  def create_notification(options)
    Notification.create!(
      user: @user,
      title: options[:title],
      message: options[:message],
      notification_type: options[:notification_type],
      read_status: options[:read_status] || false
    )
  end

  def mark_as_read(notification_id)
    notification = Notification.find_by(id: notification_id, user: @user)
    notification.update!(read_status: true) if notification
  end

  def unread_count
    Notification.where(user: @user, read_status: false).count
  end
end

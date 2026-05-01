class ReminderSenderService
  def initialize(reminder)
    @reminder = reminder
    @user = @reminder.unit.property.user
  end

  def send_reminder
    return false unless can_send?

    success = case @reminder.channel
    when "sms"
                send_sms
    when "notification"
                send_notification
    else
                false
    end

    if success
      @reminder.update(status: :sent, sent_at: Time.current)
    else
      @reminder.update(status: :failed, failed_at: Time.current)
    end

    success
  end

  private

  def can_send?
    return true if @user.admin?

    case @reminder.channel
    when "sms"
      PlanAccessService.can_send_sms?(@user)
    else
      true # notifications always allowed
    end
  end

  def send_sms
    success = SmsService.send_sms(@reminder.tenant.phone, @reminder.message)
    if success && @reminder.channel == "sms"
      @user.subscription.increment!(:sms_used)
    end
    success
  end

  def send_notification
    # For now, assume notifications are in-app, so just mark as sent
    true
  end
end

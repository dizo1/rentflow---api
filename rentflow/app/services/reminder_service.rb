class ReminderService
  def initialize(user)
    @user = user
  end

  def call
    # This method will be called periodically (e.g., by a cron job) to check for triggers
    # and create reminders accordingly.
    detect_rent_due_triggers
    detect_rent_overdue_triggers
    detect_lease_expiry_triggers
    detect_maintenance_followup_triggers
  end

  private

  def detect_rent_due_triggers
    # Find rent records due tomorrow (for the current user's properties)
    tomorrow = Date.tomorrow
    rent_records_due_tomorrow = RentRecord.joins(unit: :property)
                                          .where(properties: { user_id: @user.id })
                                          .where(due_date: tomorrow)
                                          .where.not(status: [ "paid", "waived" ])

    rent_records_due_tomorrow.each do |rent_record|
      # Check if a reminder for this rent record and type already exists
      unless Reminder.exists?(rent_record_id: rent_record.id, reminder_type: "rent_due")
        create_rent_due_reminder(rent_record)
      end
    end
  end

  def create_rent_due_reminder(rent_record)
    tenant = rent_record.unit.tenant
    unit = rent_record.unit

    message = "Reminder: Rent for #{unit.unit_number} is due tomorrow (#{rent_record.due_date}). Amount due: #{rent_record.amount_due}."

    Reminder.create!(
      tenant: tenant,
      unit: unit,
      rent_record: rent_record,
      reminder_type: "rent_due",
      message: message,
      channel: "sms", # Default to SMS, but can be configured
      status: "pending",
      scheduled_for: rent_record.due_date - 1.day # Scheduled for tomorrow at the same time? We'll adjust as needed.
    )

    # Also create an internal notification for the landlord
    NotificationService.new(@user).create_notification(
      title: "Rent Due Reminder Sent",
      message: "A rent due reminder has been sent for #{unit.unit_number} (tenant: #{tenant.full_name}).",
      notification_type: "reminder_sent"
    )
  end

  def detect_rent_overdue_triggers
    # Find overdue rent records (today > due_date AND balance > 0) for the current user's properties
    overdue_rent_records = RentRecord.joins(unit: :property)
                                     .where(properties: { user_id: @user.id })
                                     .where("due_date < ? AND balance > 0", Date.current)
                                     .where(status: [ "pending", "overdue" ]) # Assuming pending or overdue status

    overdue_rent_records.each do |rent_record|
      # Check if an overdue reminder for this rent record already exists
      unless Reminder.exists?(rent_record_id: rent_record.id, reminder_type: "rent_overdue")
        create_rent_overdue_reminder(rent_record)
      end
    end
  end

  def create_rent_overdue_reminder(rent_record)
    tenant = rent_record.unit.tenant
    unit = rent_record.unit

    message = "Overdue: Rent for #{unit.unit_number} is overdue since #{rent_record.due_date}. Amount due: #{rent_record.balance}."

    Reminder.create!(
      tenant: tenant,
      unit: unit,
      rent_record: rent_record,
      reminder_type: "rent_overdue",
      message: message,
      channel: "sms",
      status: "pending",
      scheduled_for: Time.current # Send immediately
    )

    NotificationService.new(@user).create_notification(
      title: "Rent Overdue Reminder Sent",
      message: "An overdue rent reminder has been sent for #{unit.unit_number} (tenant: #{tenant.full_name}).",
      notification_type: "reminder_sent"
    )
  end

  def detect_lease_expiry_triggers
    # Find leases ending in the next 7 days (configurable) for the current user's properties
    lease_expiry_window = 7.days.from_now
    tenants_with_lease_expiring = Tenant.joins(unit: :property)
                                        .where(properties: { user_id: @user.id })
                                        .where("lease_end BETWEEN ? AND ?", Date.current, lease_expiry_window)
                                        .where(status: "active")

    tenants_with_lease_expiring.each do |tenant|
      # Check if a lease expiry reminder for this tenant already exists
      unless Reminder.exists?(tenant_id: tenant.id, reminder_type: "lease_expiry")
        create_lease_expiry_reminder(tenant)
      end
    end
  end

  def create_lease_expiry_reminder(tenant)
    unit = tenant.unit

    message = "Lease Expiry: The lease for #{unit.unit_number} (tenant: #{tenant.full_name}) ends on #{tenant.lease_end}. Please arrange for renewal or move-out."

    Reminder.create!(
      tenant: tenant,
      unit: unit,
      reminder_type: "lease_expiry",
      message: message,
      channel: "notification", # This might be better as an internal notification first? But requirement says channel can be sms or notification.
      status: "pending",
      scheduled_for: Date.current # Send today
    )

    NotificationService.new(@user).create_notification(
      title: "Lease Expiry Reminder Sent",
      message: "A lease expiry reminder has been sent for #{unit.unit_number} (tenant: #{tenant.full_name}).",
      notification_type: "reminder_sent"
    )
  end

  def detect_maintenance_followup_triggers
    # Find maintenance logs that are unresolved (pending or in_progress) and older than, say, 3 days
    unresolved_maintenance_logs = MaintenanceLog.joins(unit: :property)
                                                .where(properties: { user_id: @user.id })
                                                .where(status: [ "pending", "in_progress" ])
                                                .where("reported_date <= ?", 3.days.ago)

    unresolved_maintenance_logs.each do |maintenance_log|
      # Check if a maintenance followup reminder for this maintenance log already exists
      unless Reminder.exists?(maintenance_log_id: maintenance_log.id, reminder_type: "maintenance_followup")
        create_maintenance_followup_reminder(maintenance_log)
      end
    end
  end

  def create_maintenance_followup_reminder(maintenance_log)
    unit = maintenance_log.unit.reload
    tenant = unit.tenant

    # Only create reminder if unit has a tenant
    return unless tenant.present?

    message = "Maintenance Follow-up: The maintenance request for #{unit.unit_number} (title: #{maintenance_log.title}) has been unresolved for #{((Time.current - maintenance_log.reported_date.to_time) / 1.day).to_i} days. Please follow up."

    Reminder.create!(
      tenant: tenant,
      unit: unit,
      maintenance_log: maintenance_log,
      reminder_type: "maintenance_followup",
      message: message,
      channel: "sms",
      status: "pending",
      scheduled_for: Time.current
    )

    NotificationService.new(@user).create_notification(
      title: "Maintenance Follow-up Reminder Sent",
      message: "A maintenance follow-up reminder has been sent for #{unit.unit_number}.",
      notification_type: "reminder_sent"
    )
  end
end

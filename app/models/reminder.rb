class Reminder < ApplicationRecord
  belongs_to :tenant
  belongs_to :unit
  belongs_to :rent_record, optional: true
  belongs_to :maintenance_log, optional: true

  # Enums
  enum :reminder_type, {
    rent_due: "rent_due",
    rent_overdue: "rent_overdue",
    payment_confirmation: "payment_confirmation",
    lease_expiry: "lease_expiry",
    maintenance_followup: "maintenance_followup",
    maintenance_resolution: "maintenance_resolution",
    manual_followup: "manual_followup"
  }, validate: true

  enum :channel, {
    sms: "sms",
    notification: "notification"
  }, validate: true

  enum :status, {
    pending: "pending",
    scheduled: "scheduled",
    sent: "sent",
    failed: "failed",
    cancelled: "cancelled",
    retried: "retried"
  }, validate: true

  # Validations
  validates :message, presence: true
  validates :scheduled_for, presence: true
  validates :reminder_type, presence: true
  validates :channel, presence: true
  validates :status, presence: true

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :sent, -> { where(status: "sent") }
  scope :failed, -> { where(status: "failed") }
  scope :due_now, -> { where("scheduled_for <= ? AND status IN (?)", Time.current, %w[pending scheduled]) }
  scope :for_user, ->(user_id) { joins(unit: :property).where(properties: { user_id: user_id }) }
end

class Tenant < ApplicationRecord
  belongs_to :unit
  has_many :rent_records, dependent: :nullify
  has_many :reminders, dependent: :destroy

  # Enums
  enum :status, {
    active: "active",
    vacated: "vacated",
    pending_move_in: "pending_move_in",
    blacklisted: "blacklisted"
  }, validate: true

  # Validations
  validates :full_name, presence: true, length: { maximum: 255 }
  validates :phone, presence: true, length: { maximum: 50 }
  validates :email,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email" },
            allow_blank: true,
            uniqueness: { case_sensitive: false }
  validates :national_id, length: { maximum: 50 }, allow_blank: true
  validates :move_in_date, presence: true
  validates :lease_start, presence: true
  validates :lease_end, presence: true
  validate :lease_dates_must_be_valid
  validates :emergency_contact, length: { maximum: 255 }, allow_blank: true
  validates :status, presence: true

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :vacated, -> { where(status: :vacated) }
  scope :pending_move_in, -> { where(status: :pending_move_in) }
  scope :blacklisted, -> { where(status: :blacklisted) }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  # Dashboard metrics for this tenant (useful for tenant portal later)
  def dashboard_summary
    {
      full_name: full_name,
      status: status,
      lease_start: lease_start,
      lease_end: lease_end,
      days_until_lease_end: (lease_end - Date.current).to_i,
      rent_records_count: rent_records.count,
      overdue_balance: rent_records.overdue.sum(:balance).to_f,
      total_paid: rent_records.sum(:amount_paid).to_f
    }
  end

  # Callbacks
  before_validation :normalize_email
  after_update :update_unit_occupancy, if: -> { saved_change_to_status? }

  private

  def lease_dates_must_be_valid
    return if lease_start.blank? || lease_end.blank?

    if lease_end < lease_start
      errors.add(:lease_end, "must be after lease start date")
    end

    if move_in_date.present? && move_in_date < lease_start
      errors.add(:move_in_date, "cannot be before lease start")
    end
  end

  def normalize_email
    self.email = email.to_s.downcase.strip if email.present?
  end

  def update_unit_occupancy
    unit.update(occupancy_status: status == "active" ? "occupied" : "vacant")
  end
end

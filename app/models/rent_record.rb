class RentRecord < ApplicationRecord
  belongs_to :unit
  belongs_to :tenant, optional: true

   # Enums - string-based for readability and query compatibility
   enum :status, {
     pending: 'pending',
     unpaid: 'unpaid',
     partial: 'partial',
     paid: 'paid',
     overdue: 'overdue',
     waived: 'waived'
   }, validate: true, suffix: true

    before_validation :set_defaults, on: :create

  # Validations
  validates :amount_due, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :amount_paid, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :due_date, presence: true
  validates :month, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :year, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 2000 }
  validates :status, presence: true
  validate :tenant_must_belong_to_unit

  # Callbacks — ORDER MATTERS, set_defaults must be last
  before_validation :set_paid_at, if: -> { status == 'paid' && paid_at.nil? }
  before_validation :associate_tenant_from_unit, if: -> { tenant_id.nil? && unit.present? && unit.tenant.present? }
  before_validation :calculate_balance, if: -> { new_record? || will_save_change_to_amount_due? || will_save_change_to_amount_paid? }
  before_validation :auto_adjust_status, if: -> { amount_due_changed? || amount_paid_changed? || due_date_changed? }, unless: :status_changed?
  before_validation :set_defaults, on: :create

  # Scopes
  scope :by_month_year, ->(month, year) { where(month: month, year: year) }
  scope :overdue, -> { where(status: 'overdue') }
  scope :paid, -> { where(status: 'paid') }
  scope :pending_or_overdue, -> { where(status: ['pending', 'unpaid', 'overdue']) }
  scope :for_tenant, ->(tenant_id) { where(tenant_id: tenant_id) }
  scope :for_unit, ->(unit_id) { where(unit_id: unit_id) }
  scope :recent, -> { order(created_at: :desc) }

  # Business logic methods

  # Record a payment against this rent record
  # @param payment_amount [BigDecimal, Float, Numeric] amount being paid now
  # @return [Boolean] success
  def record_payment!(payment_amount)
    raise ArgumentError, 'Payment must be positive' unless payment_amount.to_f > 0

    self.amount_paid = (self.amount_paid.to_f + payment_amount).to_d
    save!
    # Status auto-adjusted by callback
    true
  end

  # Waive the remaining balance (e.g., landlord forgives rent)
  def waive_balance!(waiver_amount = balance)
    raise ArgumentError, 'Waiver amount exceeds balance' if waiver_amount.to_d > balance

    self.amount_paid = (self.amount_paid.to_f + waiver_amount).to_d
    self.balance = amount_due - amount_paid
    self.status = 'waived'
    save!
  end

  # Mark as paid (full settlement)
  def mark_fully_paid!
    self.amount_paid = amount_due
    self.balance = 0
    self.status = 'paid'
    self.paid_at ||= Time.current
    save!
  end

  def overdue?
    status == 'overdue'
  end

  def fully_paid?
    status == 'paid' || status == 'waived'
  end

  def outstanding_balance
    balance.to_f
  end

  def days_overdue
    return 0 unless overdue?
    (Date.current - due_date).to_i
  end

  # JSON serialization helpers
  def tenant_full_name
    tenant&.full_name
  end

  def tenant_phone
    tenant&.phone
  end

  # Class methods for administrative/operational tasks

  # Batch generate rent records for all occupied units in a property
  # Delegates to RentRecordGenerator service
  def self.generate_monthly_for_property(property, month:, year:, due_day: 1)
    RentRecordGenerator.generate(property: property, month: month, year: year, due_day: due_day)
  end

  # Mark all overdue records (to be called by a daily cron job)
  def self.mark_all_overdue!
    where('due_date < ? AND balance > 0', Date.current)
      .where.not(status: 'overdue')
      .update_all(status: 'overdue')
  end

  # Find all overdue records regardless of status flag (query-based)
  def self.find_overdue
    where('due_date < ? AND balance > 0', Date.current)
  end

  private

  def set_defaults
    self.amount_paid ||= 0
    self.balance = amount_due.to_f - self.amount_paid.to_f
  end

  # Ensure tenant belongs to the same unit (data integrity)
  def tenant_must_belong_to_unit
    return if tenant_id.nil? # Allow nil for legacy/migration records
    return unless unit_id.present? && tenant_id.present?

    tenant_record = unit.tenant
    if tenant_record && tenant_record.id != tenant_id
      errors.add(:tenant, "must be the tenant of the associated unit")
    end
  end

  # Auto-associate tenant from unit if not explicitly set
  def associate_tenant_from_unit
    self.tenant = unit.tenant if unit&.tenant
  end

  # Calculate balance = amount_due - amount_paid
  def calculate_balance
    return if amount_due.nil? || amount_paid.nil?

    # For new records, skip if balance already explicitly set
    if new_record?
      balance_attr = @attributes['balance']
      return if balance_attr&.came_from_user?
    else
      # For existing records, only recalc if financials changed
      return unless will_save_change_to_amount_due? || will_save_change_to_amount_paid?
    end

    self.balance = amount_due - amount_paid
  end

  # Set paid_at timestamp when status becomes paid
  def set_paid_at
    self.paid_at ||= Time.current
  end

  # Auto-adjust status based on payment and due date
  def auto_adjust_status
    # If user explicitly set status (status_changed?), respect it and skip auto-adjustment
    # unless we are in a state that contradicts business rules (like paid but balance > 0)
    # In that case we enforce consistency.

    # Ensure consistency: if balance <= 0, must be paid or waived
    if balance <= 0
      self.status = 'paid' unless %w[paid waived].include?(status)
      self.paid_at ||= Time.current if status == 'paid'
    # If there's a balance
    elsif balance > 0
      if due_date.past?
        self.status = 'overdue' unless status == 'waived'
      else
        # Not yet due, but some payment made => partial
        if amount_paid.to_i > 0
          self.status = 'partial' unless status == 'waived'
        else
          self.status = 'pending' unless status == 'waived'
        end
      end
    end
  end

  # Placeholder for future notification integration
  def notify_status_change
    # NotificationService.rent_status_changed(self)
  end
end

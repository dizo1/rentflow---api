class RentRecord < ApplicationRecord
  belongs_to :unit

  validates :amount_due, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :amount_paid, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :due_date, presence: true
  enum :status, { pending: 'pending', unpaid: 'unpaid', paid: 'paid', partial: 'partial', overdue: 'overdue' }, validate: true
  validates :month, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :year, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 2000 }

  validate :amount_paid_cannot_exceed_amount_due
  validate :balance_must_be_consistent

  before_validation :set_paid_at, if: -> { status == 'paid' && paid_at.nil? }
  before_validation :calculate_balance, if: -> { new_record? || amount_due_changed? || amount_paid_changed? }

  after_update :update_unit_occupancy_if_fully_paid, if: -> { saved_change_to_status? && status == 'paid' }

  private

  def calculate_balance
    return if amount_due.nil? || amount_paid.nil?

    if new_record?
      # Only auto-calculate if balance was not explicitly set by the user
      balance_attr = @attributes['balance']
      return if balance_attr&.came_from_user?
    else
      # For existing records, only recalc if amounts changed
      return unless amount_due_changed? || amount_paid_changed?
    end
    self.balance = amount_due - amount_paid
  end

  def set_paid_at
    self.paid_at ||= Time.current
  end

  def amount_paid_cannot_exceed_amount_due
    return if amount_paid.blank? || amount_due.blank?
    if amount_paid > amount_due
      errors.add(:amount_paid, "cannot exceed amount due")
    end
  end

  def balance_must_be_consistent
    return if amount_due.blank? || amount_paid.blank?
    if !balance.nil? && (amount_due - amount_paid) != balance
      errors.add(:balance, "must be consistent with amount due and amount paid")
    end
  end

  def update_unit_occupancy_if_fully_paid
    # Optional: Add logic to update unit status if all rent records are paid
  end
end
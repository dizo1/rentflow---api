class Unit < ApplicationRecord
  belongs_to :property
  has_many :rent_records, dependent: :destroy
  has_many :maintenance_logs, dependent: :destroy

  enum :occupancy_status, { occupied: 'occupied', vacant: 'vacant' }, validate: true

  validates :unit_number, presence: true, uniqueness: { scope: :property_id }
  validates :rent_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :deposit_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :occupancy_status, presence: true
  validates :tenant_name, presence: true
  validates :tenant_phone, presence: true

  validate :rent_amount_should_be_positive

  def current_rent_record
    rent_records.order(year: :desc, month: :desc).first
  end

  def pending_rent_records
    rent_records.where(status: ['pending', 'overdue'])
  end

  def rent_fully_paid_for?(month:, year:)
    record = rent_records.find_by(month: month, year: year)
    record&.status == 'paid'
  end

  def open_maintenance_logs
    maintenance_logs.where(status: ['pending', 'in_progress'])
  end

  def resolved_maintenance_logs
    maintenance_logs.where(status: 'resolved')
  end

  # Generate a rent record for this unit for a specific month/year
  def generate_rent_record(month: Date.current.month, year: Date.current.year, due_day: 1)
    raise ArgumentError, 'Month must be 1-12' unless (1..12).cover?(month)
    raise ArgumentError, 'Year must be >= 2000' unless year >= 2000

    # Check if already exists
    existing = rent_records.where(month: month, year: year).first
    return existing if existing

    due_date = Date.new(year, month, due_day)

    rent_records.create(
      amount_due: rent_amount,
      amount_paid: 0,
      balance: rent_amount,
      due_date: due_date,
      status: 'pending',
      month: month,
      year: year
    )
  end

  private

  def rent_amount_should_be_positive
    return if rent_amount.blank?
    if rent_amount <= 0
      errors.add(:rent_amount, "must be greater than zero")
    end
  end
end
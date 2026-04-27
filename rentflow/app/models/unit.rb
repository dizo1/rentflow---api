class Unit < ApplicationRecord
  belongs_to :property
  has_many :rent_records, dependent: :destroy

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

  private

  def rent_amount_should_be_positive
    return if rent_amount.blank?
    if rent_amount <= 0
      errors.add(:rent_amount, "must be greater than zero")
    end
  end
end

class Unit < ApplicationRecord
  belongs_to :property

  enum :occupancy_status, { occupied: 'occupied', vacant: 'vacant' }, validate: true

  validates :unit_number, presence: true
  validates :rent_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :deposit_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :occupancy_status, presence: true
  validates :tenant_name, presence: true
  validates :tenant_phone, presence: true
end

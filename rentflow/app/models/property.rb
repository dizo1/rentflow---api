class Property < ApplicationRecord
  belongs_to :user
  has_many :units, dependent: :destroy

  enum(:property_type, { rentals: 'rentals', apartment: 'apartment', house: 'house', commercial: 'commercial' })
  enum(:status, { occupied: 'occupied', vacant: 'vacant' })

  validates :name, presence: true
  validates :property_type, presence: true
  validates :address, presence: true
  validates :status, presence: true
  validates :total_units, presence: true,
                          numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :total_units_matches_actual_units, on: :update

  # Dashboard hook - returns property-level metrics
  def dashboard_data
    {
      id: id,
      name: name,
      address: address,
      property_type: property_type,
      status: status,
      total_units: total_units,
      units_count: units.count,
      occupied_units: units.where(occupancy_status: 'occupied').count,
      vacant_units: units.where(occupancy_status: 'vacant').count,
      occupancy_rate: total_units > 0 ? (units.where(occupancy_status: 'occupied').count.to_f / total_units * 100).round(2) : 0.0,
      monthly_revenue: units.sum(:rent_amount).to_f,
      total_deposits: units.sum(:deposit_amount).to_f
    }
  end

  private

  def total_units_matches_actual_units
    if total_units != units.size && units.size > 0
      errors.add(:total_units, "does not match actual units count (#{units.size})")
    end
  end
end

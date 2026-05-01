# Service object for generating monthly rent records
# Usage: RentRecordGenerator.generate(property: property, month: 4, year: 2025)
# Returns { generated: Integer, skipped: Integer, errors: Array<String> }
class RentRecordGenerator
  class << self
    def generate(property:, month: Date.current.month, year: Date.current.year, due_day: 1)
      new(property, month, year, due_day).call
    end
  end

  def initialize(property, month, year, due_day = 1)
    @property = property
    @month = month
    @year = year
    @due_date = Date.new(year, month, due_day)
    validate_args!
  end

  def call
    results = { generated: 0, skipped: 0, errors: [] }

    # Only generate for occupied units that have an active tenant
    occupied_units = @property.units.occupied.joins(:tenant).where(tenants: { status: 'active' }).includes(:tenant)

    occupied_units.find_each do |unit|
      # Skip if rent record already exists for this unit/month/year
      existing = unit.rent_records.find_by(month: @month, year: @year)
      if existing
        results[:skipped] += 1
        next
      end

      # Build rent record with tenant association
      rent_record = unit.rent_records.build(
        amount_due: unit.rent_amount,
        amount_paid: 0,
        balance: unit.rent_amount,
        due_date: @due_date,
        status: 'pending',
        month: @month,
        year: @year,
        tenant: unit.tenant # Auto-associate tenant
      )

      if rent_record.save
        results[:generated] += 1
      else
        results[:skipped] += 1
        results[:errors] << "Unit #{unit.unit_number}: #{rent_record.errors.full_messages.join(', ')}"
      end
    end

    results
  end

  private

  def validate_args!
    raise ArgumentError, 'Month must be 1-12' unless (1..12).cover?(@month)
    raise ArgumentError, 'Year must be >= 2000' unless @year >= 2000
  end
end

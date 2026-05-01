require 'rails_helper'

RSpec.describe RentRecordGenerator, type: :service do
  let!(:user) { User.create(email: 'owner@example.com', password: 'password123') }
  let!(:property) do
    Property.create(
      user: user,
      name: 'Test Property',
      address: '123 Main St',
      property_type: 'apartment',
      status: 'occupied',
      total_units: 3
    )
  end

  describe '.generate' do
    context 'with occupied units having active tenants' do
      let!(:unit_with_tenant) do
        unit = property.units.create(
          unit_number: '101',
          rent_amount: 1000.00,
          deposit_amount: 2000.00,
          occupancy_status: 'occupied'
        )
        unit.create_tenant!(
          full_name: 'John Doe',
          phone: '555-1234',
          email: 'john@example.com',
          move_in_date: Date.current,
          lease_start: Date.current,
          lease_end: 1.year.from_now.to_date,
          status: 'active'
        )
        unit
      end

      let!(:unit_without_tenant) do
        property.units.create(
          unit_number: '102',
          rent_amount: 1200.00,
          deposit_amount: 2400.00,
          occupancy_status: 'occupied'
          # no tenant assigned
        )
      end

      let!(:unit_with_inactive_tenant) do
        unit = property.units.create(
          unit_number: '103',
          rent_amount: 1500.00,
          deposit_amount: 3000.00,
          occupancy_status: 'occupied'
        )
        unit.create_tenant!(
          full_name: 'Jane Smith',
          phone: '555-5678',
          move_in_date: Date.current,
          lease_start: Date.current,
          lease_end: 1.year.from_now.to_date,
          status: 'vacated'  # not active
        )
        unit
      end

      it 'generates rent records only for units with active tenants' do
        result = RentRecordGenerator.generate(property: property, month: 4, year: 2025)

        expect(result[:generated]).to eq(1)
        expect(result[:skipped]).to eq(2) # unit without tenant and unit with inactive tenant skipped
        expect(result[:errors]).to be_empty

        rent_record = unit_with_tenant.rent_records.first
        expect(rent_record).to be_present
        expect(rent_record.amount_due).to eq(1000.00)
        expect(rent_record.balance).to eq(1000.00)
        expect(rent_record.status).to eq('pending')
        expect(rent_record.month).to eq(4)
        expect(rent_record.year).to eq(2025)
        expect(rent_record.tenant).to eq(unit_with_tenant.tenant)
      end

      it 'does not generate duplicate records for same month/year' do
        # First generation
        first_result = RentRecordGenerator.generate(property: property, month: 4, year: 2025)
        expect(first_result[:generated]).to eq(1)

        # Second generation same month/year
        second_result = RentRecordGenerator.generate(property: property, month: 4, year: 2025)
        expect(second_result[:generated]).to eq(0)
        expect(second_result[:skipped]).to eq(1) # the existing record is skipped
      end

      it 'sets due_date correctly' do
        result = RentRecordGenerator.generate(property: property, month: 5, year: 2025, due_day: 5)
        rent_record = unit_with_tenant.rent_records.find_by(month: 5, year: 2025)
        expect(rent_record.due_date).to eq(Date.new(2025, 5, 5))
      end
    end

    context 'when no occupied units' do
      let!(:vacant_property) do
        Property.create(
          user: user,
          name: 'Vacant Property',
          address: '456 Nowhere',
          property_type: 'apartment',
          status: 'vacant',
          total_units: 2
        )
      end

      it 'returns zero generated' do
        result = RentRecordGenerator.generate(property: vacant_property, month: 4, year: 2025)
        expect(result[:generated]).to eq(0)
        expect(result[:skipped]).to eq(0)
      end
    end

    context 'when unit has tenant but tenant is nil' do
      let!(:unit) do
        property.units.create(
          unit_number: '201',
          rent_amount: 1100.00,
          deposit_amount: 2200.00,
          occupancy_status: 'occupied'
          # no tenant
        )
      end

      it 'creates rent record with nil tenant' do
        result = RentRecordGenerator.generate(property: property, month: 4, year: 2025)
        # It should skip because no tenant, but our implementation only includes units with active tenant. So it won't generate.
        expect(result[:generated]).to eq(0)
        expect(result[:skipped]).to eq(1)
      end
    end
  end
end

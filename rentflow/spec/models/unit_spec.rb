require 'rails_helper'

RSpec.describe Unit, type: :model do
  let!(:user) { User.create(email: 'owner@example.com', password: 'password123') }
  let!(:property) do
    Property.create(
      user: user,
      name: 'Test Property',
      address: '123 St',
      property_type: 'apartment',
      status: 'occupied',
      total_units: 5
    )
  end

  it 'is valid with all required attributes' do
    unit = Unit.new(
      property: property,
      unit_number: '101',
      rent_amount: 1200.00,
      deposit_amount: 2400.00,
      occupancy_status: 'occupied',
      tenant_name: 'John Doe',
      tenant_phone: '555-1234'
    )
    expect(unit).to be_valid
  end

  it 'belongs to a property' do
    association = described_class.reflect_on_association(:property)
    expect(association.macro).to eq(:belongs_to)
  end

  it 'is invalid without a unit_number' do
    unit = Unit.new(property: property, unit_number: nil)
    expect(unit).not_to be_valid
    expect(unit.errors[:unit_number]).to include("can't be blank")
  end

  it 'is invalid without rent_amount' do
    unit = Unit.new(property: property, rent_amount: nil)
    expect(unit).not_to be_valid
    expect(unit.errors[:rent_amount]).to include("can't be blank")
  end

  it 'is invalid with negative rent_amount' do
    unit = Unit.new(property: property, rent_amount: -100)
    expect(unit).not_to be_valid
    expect(unit.errors[:rent_amount]).to include("must be greater than or equal to 0")
  end

  it 'is invalid without deposit_amount' do
    unit = Unit.new(property: property, deposit_amount: nil)
    expect(unit).not_to be_valid
    expect(unit.errors[:deposit_amount]).to include("can't be blank")
  end

  it 'is invalid with negative deposit_amount' do
    unit = Unit.new(property: property, deposit_amount: -500)
    expect(unit).not_to be_valid
    expect(unit.errors[:deposit_amount]).to include("must be greater than or equal to 0")
  end

  it 'is invalid without occupancy_status' do
    unit = Unit.new(property: property, occupancy_status: nil)
    expect(unit).not_to be_valid
    expect(unit.errors[:occupancy_status]).to include("can't be blank")
  end

  it 'is invalid without tenant_name' do
    unit = Unit.new(property: property, tenant_name: nil)
    expect(unit).not_to be_valid
    expect(unit.errors[:tenant_name]).to include("can't be blank")
  end

  it 'is invalid without tenant_phone' do
    unit = Unit.new(property: property, tenant_phone: nil)
    expect(unit).not_to be_valid
    expect(unit.errors[:tenant_phone]).to include("can't be blank")
  end

  it 'destroys units when property is destroyed' do
    unit = property.units.create(
      unit_number: '101',
      rent_amount: 1200.00,
      deposit_amount: 2400.00,
      occupancy_status: 'occupied',
      tenant_name: 'John Doe',
      tenant_phone: '555-1234'
    )
    expect { property.destroy }.to change { Unit.count }.by(-1)
  end

  it 'supports occupancy_status enum values' do
    expect(Unit.occupancy_statuses.keys).to match_array(%w[occupied vacant])
  end

  it 'is invalid with invalid occupancy_status' do
    unit = Unit.new(property: property, unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'invalid_status', tenant_name: 'John', tenant_phone: '555-1234')
    expect(unit).not_to be_valid
    expect(unit.errors[:occupancy_status]).to include("is not included in the list")
  end

  describe 'associations' do
    it 'has many rent_records' do
      association = described_class.reflect_on_association(:rent_records)
      expect(association.macro).to eq(:has_many)
    end

    it 'destroys associated rent_records when destroyed' do
      unit = property.units.create(
        unit_number: '101',
        rent_amount: 1200.00,
        deposit_amount: 2400.00,
        occupancy_status: 'occupied',
        tenant_name: 'John Doe',
        tenant_phone: '555-1234'
      )
      unit.rent_records.create(
        amount_due: 1200,
        amount_paid: 0,
        balance: 1200,
        due_date: Date.current,
        status: 'pending',
        month: 1,
        year: 2024
      )
      expect { unit.destroy }.to change { RentRecord.count }.by(-1)
    end
  end

  describe 'validations' do
    context 'with duplicate unit_number for same property' do
      it 'is invalid' do
        property.units.create(
          unit_number: '101',
          rent_amount: 1200.00,
          deposit_amount: 2400.00,
          occupancy_status: 'occupied',
          tenant_name: 'Jane Doe',
          tenant_phone: '555-5678'
        )
        unit2 = property.units.build(
          unit_number: '101',
          rent_amount: 1300.00,
          deposit_amount: 2600.00,
          occupancy_status: 'vacant',
          tenant_name: 'Bob Smith',
          tenant_phone: '555-9012'
        )
        expect(unit2).not_to be_valid
        expect(unit2.errors[:unit_number]).to include("has already been taken")
      end
    end

    context 'with unit_number unique across different properties' do
      it 'is valid' do
        property2 = Property.create(
          user: user,
          name: 'Second Property',
          address: '456 Other St',
          property_type: 'apartment',
          status: 'occupied',
          total_units: 10
        )
        unit2 = property2.units.build(
          unit_number: '101',
          rent_amount: 1200.00,
          deposit_amount: 2400.00,
          occupancy_status: 'vacant',
          tenant_name: 'Alice Brown',
          tenant_phone: '555-3456'
        )
        expect(unit2).to be_valid
      end
    end

    context 'with zero or negative rent_amount' do
      it 'is invalid when rent_amount is zero' do
        unit = property.units.build(
          unit_number: '102',
          rent_amount: 0,
          deposit_amount: 2400.00,
          occupancy_status: 'occupied',
          tenant_name: 'John Doe',
          tenant_phone: '555-1234'
        )
        expect(unit).not_to be_valid
        expect(unit.errors[:rent_amount]).to include("must be greater than zero")
      end
    end
  end

  describe 'rent_records helpers' do
    let!(:unit) do
      property.units.create(
        unit_number: '101',
        rent_amount: 1200.00,
        deposit_amount: 2400.00,
        occupancy_status: 'occupied',
        tenant_name: 'John Doe',
        tenant_phone: '555-1234'
      )
    end
    let!(:recent_record) do
      unit.rent_records.create(
        amount_due: 1200,
        amount_paid: 1200,
        balance: 0,
        due_date: Date.current,
        status: 'paid',
        month: Date.current.month,
        year: Date.current.year,
        paid_at: Time.current
      )
    end
    let!(:old_record) do
      unit.rent_records.create(
        amount_due: 1200,
        amount_paid: 0,
        balance: 1200,
        due_date: 1.month.ago,
        status: 'pending',
        month: 1.month.ago.month,
        year: 1.month.ago.year,
        paid_at: nil
      )
    end

    describe '#current_rent_record' do
      it 'returns the most recent rent record' do
        expect(unit.current_rent_record).to eq(recent_record)
      end
    end

    describe '#pending_rent_records' do
      it 'returns only pending and overdue records' do
        expect(unit.pending_rent_records).to match_array([old_record])
      end
    end

    describe '#rent_fully_paid_for?' do
      it 'returns true when rent is paid for given month and year' do
        expect(unit.rent_fully_paid_for?(month: Date.current.month, year: Date.current.year)).to be true
      end

      it 'returns false when rent is not paid for given month and year' do
        expect(unit.rent_fully_paid_for?(month: 1.month.ago.month, year: 1.month.ago.year)).to be false
      end
    end
  end
end
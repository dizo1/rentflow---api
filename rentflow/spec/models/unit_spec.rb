require 'rails_helper'

RSpec.describe Unit, type: :model do
  let(:user) { User.create(email: 'owner@example.com', password: 'password123') }
  let(:property) { Property.create(user: user, name: 'Test Property', address: '123 St', property_type: 'apartment', status: 'occupied', total_units: 5) }

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
    expect(unit.errors[:rent_amount]).to include('must be greater than or equal to 0')
  end

  it 'is invalid without deposit_amount' do
    unit = Unit.new(property: property, deposit_amount: nil)
    expect(unit).not_to be_valid
    expect(unit.errors[:deposit_amount]).to include("can't be blank")
  end

  it 'is invalid with negative deposit_amount' do
    unit = Unit.new(property: property, deposit_amount: -500)
    expect(unit).not_to be_valid
    expect(unit.errors[:deposit_amount]).to include('must be greater than or equal to 0')
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
end

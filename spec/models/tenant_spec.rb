require 'rails_helper'

RSpec.describe Tenant, type: :model do
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
  let!(:unit) do
    Unit.create(
      property: property,
      unit_number: '101',
      rent_amount: 1200.00,
      deposit_amount: 2400.00,
      occupancy_status: 'occupied'
    )
  end

  it 'is valid with all required attributes' do
    tenant = Tenant.new(
      unit: unit,
      full_name: 'John Doe',
      phone: '555-1234',
      email: 'john@example.com',
      national_id: '123456789',
      move_in_date: Date.current,
      lease_start: Date.current,
      lease_end: 1.year.from_now.to_date,
      status: 'pending_move_in',
      emergency_contact: 'Jane Doe: 555-5678'
    )
    expect(tenant).to be_valid
  end

  it 'belongs to a unit' do
    association = described_class.reflect_on_association(:unit)
    expect(association.macro).to eq(:belongs_to)
  end

  it 'is invalid without full_name' do
    tenant = Tenant.new(unit: unit, full_name: nil)
    expect(tenant).not_to be_valid
    expect(tenant.errors[:full_name]).to include("can't be blank")
  end

  it 'is invalid without phone' do
    tenant = Tenant.new(unit: unit, phone: nil)
    expect(tenant).not_to be_valid
    expect(tenant.errors[:phone]).to include("can't be blank")
  end

  it 'is invalid with duplicate email' do
    Tenant.create!(
      unit: unit,
      full_name: 'Jane Doe',
      phone: '555-9999',
      email: 'duplicate@example.com',
      move_in_date: Date.current,
      lease_start: Date.current,
      lease_end: 1.year.from_now.to_date,
      status: 'active'
    )
    tenant2 = Tenant.new(
      unit: unit,
      full_name: 'John Doe',
      phone: '555-1234',
      email: 'duplicate@example.com',
      move_in_date: Date.current,
      lease_start: Date.current,
      lease_end: 1.year.from_now.to_date,
      status: 'active'
    )
    expect(tenant2).not_to be_valid
    expect(tenant2.errors[:email]).to include('has already been taken')
  end

  it 'is invalid when lease_end is before lease_start' do
    tenant = Tenant.new(
      unit: unit,
      full_name: 'John Doe',
      phone: '555-1234',
      email: 'john@example.com',
      move_in_date: Date.current,
      lease_start: Date.current + 10.days,
      lease_end: Date.current,
      status: 'pending_move_in'
    )
    expect(tenant).not_to be_valid
    expect(tenant.errors[:lease_end]).to include('must be after lease start date')
  end

  it 'is invalid when move_in_date is before lease_start' do
    tenant = Tenant.new(
      unit: unit,
      full_name: 'John Doe',
      phone: '555-1234',
      email: 'john@example.com',
      move_in_date: Date.current - 10.days,
      lease_start: Date.current,
      lease_end: 1.year.from_now.to_date,
      status: 'pending_move_in'
    )
    expect(tenant).not_to be_valid
    expect(tenant.errors[:move_in_date]).to include('cannot be before lease start')
  end

  it 'accepts valid status values' do
    expect(Tenant.statuses.keys).to match_array(%w[active vacated pending_move_in blacklisted])
  end

  it 'is invalid with an invalid status' do
    tenant = Tenant.new(
      unit: unit,
      full_name: 'John Doe',
      phone: '555-1234',
      move_in_date: Date.current,
      lease_start: Date.current,
      lease_end: 1.year.from_now.to_date,
      status: 'invalid_status'
    )
    expect(tenant).not_to be_valid
    expect(tenant.errors[:status]).to include('is not included in the list')
  end

  it 'normalizes email to lowercase' do
    tenant = Tenant.create!(
      unit: unit,
      full_name: 'John Doe',
      phone: '555-1234',
      email: ' JOHN@EXAMPLE.COM ',
      move_in_date: Date.current,
      lease_start: Date.current,
      lease_end: 1.year.from_now.to_date,
      status: 'active'
    )
    expect(tenant.reload.email).to eq('john@example.com')
  end

  it 'destroys tenant when unit is destroyed' do
    tenant = Tenant.create!(
      unit: unit,
      full_name: 'John Doe',
      phone: '555-1234',
      email: 'john@example.com',
      move_in_date: Date.current,
      lease_start: Date.current,
      lease_end: 1.year.from_now.to_date,
      status: 'active'
    )
    expect { unit.destroy }.to change { Tenant.count }.by(-1)
  end

  it 'updates unit occupancy_status when tenant status becomes active' do
    tenant = Tenant.create!(
      unit: unit,
      full_name: 'John Doe',
      phone: '555-1234',
      move_in_date: Date.current,
      lease_start: Date.current,
      lease_end: 1.year.from_now.to_date,
      status: 'pending_move_in'
    )
    expect(unit.reload.occupancy_status).to eq('vacant')
    
    tenant.update!(status: 'active')
    expect(unit.reload.occupancy_status).to eq('occupied')
  end

  it 'updates unit occupancy_status when tenant becomes vacated' do
    tenant = Tenant.create!(
      unit: unit,
      full_name: 'John Doe',
      phone: '555-1234',
      move_in_date: Date.current,
      lease_start: Date.current,
      lease_end: 1.year.from_now.to_date,
      status: 'active'
    )
    expect(unit.reload.occupancy_status).to eq('occupied')

    tenant.update!(status: 'vacated')
    expect(unit.reload.occupancy_status).to eq('vacant')
  end

  describe 'scopes' do
    before do
      @unit2 = Unit.create(
        property: property,
        unit_number: '102',
        rent_amount: 1300.00,
        deposit_amount: 2600.00,
        occupancy_status: 'vacant'
      )
    end

    it 'returns only active tenants' do
      active_tenant = Tenant.create!(
        unit: unit,
        full_name: 'Active Tenant',
        phone: '555-1111',
        move_in_date: Date.current,
        lease_start: Date.current,
        lease_end: 1.year.from_now.to_date,
        status: 'active'
      )
      Tenant.create!(
        unit: @unit2,
        full_name: 'Vacated Tenant',
        phone: '555-2222',
        move_in_date: Date.current,
        lease_start: Date.current,
        lease_end: 1.year.from_now.to_date,
        status: 'vacated'
      )
      expect(Tenant.active).to eq([active_tenant])
    end

    it 'filters by status using by_status scope' do
      Tenant.create!(
        unit: unit,
        full_name: 'Active',
        phone: '555-1111',
        move_in_date: Date.current,
        lease_start: Date.current,
        lease_end: 1.year.from_now.to_date,
        status: 'active'
      )
      expect(Tenant.by_status('active').count).to eq(1)
      expect(Tenant.by_status('vacated').count).to eq(0)
    end
  end

  describe 'delegation methods' do
    it 'unit.tenant_name returns tenant full_name' do
      tenant = Tenant.create!(
        unit: unit,
        full_name: 'John Doe',
        phone: '555-1234',
        move_in_date: Date.current,
        lease_start: Date.current,
        lease_end: 1.year.from_now.to_date,
        status: 'active'
      )
      expect(unit.tenant_name).to eq('John Doe')
    end

    it 'unit.tenant_phone returns tenant phone' do
      tenant = Tenant.create!(
        unit: unit,
        full_name: 'John Doe',
        phone: '555-1234',
        move_in_date: Date.current,
        lease_start: Date.current,
        lease_end: 1.year.from_now.to_date,
        status: 'active'
      )
      expect(unit.tenant_phone).to eq('555-1234')
    end

    it 'returns nil for tenant_name when no tenant exists' do
      vacant_unit = Unit.create(
        property: property,
        unit_number: '103',
        rent_amount: 1500.00,
        deposit_amount: 3000.00,
        occupancy_status: 'vacant'
      )
      expect(vacant_unit.tenant_name).to be_nil
      expect(vacant_unit.tenant_phone).to be_nil
    end
  end
end

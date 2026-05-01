require 'rails_helper'

RSpec.describe RentRecord, type: :model do
  let!(:user) { User.create(email: 'owner@example.com', password: 'password123') }
  let!(:property) do
    Property.create(
      user: user,
      name: 'Test Property',
      address: '123 Main St',
      property_type: 'apartment',
      status: 'occupied',
      total_units: 5
    )
  end
   let!(:unit) do
     property.units.create(
       unit_number: '101',
       rent_amount: 1000.00,
       deposit_amount: 2000.00,
       occupancy_status: 'occupied'
     )
   end
   let!(:tenant) do
     Tenant.create!(
       unit: unit,
       full_name: 'John Doe',
       phone: '555-1234',
       email: 'john@example.com',
       move_in_date: Date.current,
       lease_start: Date.current,
       lease_end: 1.year.from_now.to_date,
       status: 'active'
     )
   end

   describe 'associations' do
     it 'belongs to a unit' do
       association = described_class.reflect_on_association(:unit)
       expect(association.macro).to eq(:belongs_to)
     end

     it 'belongs to a tenant (optional)' do
       association = described_class.reflect_on_association(:tenant)
       expect(association.macro).to eq(:belongs_to)
       expect(association.options[:optional]).to be true
   end

  describe 'tenant integration' do
    it 'auto-associates tenant from unit when not provided' do
      record = RentRecord.new(
        unit: unit,
        amount_due: 1000,
        amount_paid: 0,
        balance: 1000,
        due_date: Date.current,
        status: 'pending',
        month: 1,
        year: 2024
      )
      record.valid?
      expect(record.tenant).to eq(tenant)
    end

    it 'tenant must belong to the same unit' do
      other_unit = property.units.create(unit_number: '102', rent_amount: 800, deposit_amount: 1600, occupancy_status: 'occupied')
      other_tenant = Tenant.create!(unit: other_unit, full_name: 'Other Tenant', phone: '555-0000', move_in_date: Date.current, lease_start: Date.current, lease_end: 1.year.from_now.to_date, status: 'active')
      record = RentRecord.new(unit: unit, tenant: other_tenant, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 1, year: 2024)
      expect(record).not_to be_valid
      expect(record.errors[:tenant]).to include("must be the tenant of the associated unit")
    end
  end

  describe 'payment operations' do
    describe '#record_payment!' do
      it 'adds payment and updates status to partial' do
        record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        record.record_payment!(300)
        record.reload
        expect(record.amount_paid).to eq(300)
        expect(record.balance).to eq(700)
        expect(record.status).to eq('partial')
      end

      it 'marks as paid when payment clears balance' do
        record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 600, balance: 400, due_date: Date.current, status: 'partial', month: 1, year: 2024)
        record.record_payment!(400)
        record.reload
        expect(record.status).to eq('paid')
        expect(record.balance).to eq(0)
        expect(record.paid_at).to be_present
      end

      it 'raises error for non-positive payment' do
        record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        expect { record.record_payment!(0) }.to raise_error(ArgumentError, 'Payment must be positive')
      end
    end

    describe '#mark_fully_paid!' do
      it 'sets status to paid and zeroes balance' do
        record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        record.mark_fully_paid!
        expect(record.status).to eq('paid')
        expect(record.amount_paid).to eq(1000)
        expect(record.balance).to eq(0)
        expect(record.paid_at).to be_present
      end
    end

    describe '#waive_balance!' do
      it 'applies waiver and sets status to waived' do
        record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 200, balance: 800, due_date: Date.current, status: 'partial', month: 1, year: 2024)
        record.waive_balance!(500)
        record.reload
        expect(record.amount_paid).to eq(700)
        expect(record.balance).to eq(300)
        expect(record.status).to eq('waived')
      end

      it 'raises error if waiver exceeds balance' do
        record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        expect { record.waive_balance!(1500) }.to raise_error(ArgumentError, 'Waiver amount exceeds balance')
      end
    end
  end

  describe 'status auto-adjustment' do
    it 'updates to partial when amount_paid increases and balance remains positive' do
      record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 200, balance: 800, due_date: 1.week.from_now, status: 'pending', month: 1, year: 2024)
      record.update(amount_paid: 400)
      expect(record.reload.status).to eq('partial')
    end

    it 'updates to paid when balance reaches zero' do
      record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 1000, balance: 0, due_date: Date.current, status: 'pending', month: 1, year: 2024)
      record.valid?
      expect(record.status).to eq('paid')
    end

    it 'updates to overdue when due date passes and balance > 0' do
      record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: 1.week.ago, status: 'pending', month: 1, year: 2024)
      record.valid?
      expect(record.status).to eq('overdue')
    end

    it 'does not override waived status' do
      record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 500, balance: 500, due_date: Date.current, status: 'waived', month: 1, year: 2024)
      record.update(amount_paid: 600)
      expect(record.reload.status).to eq('waived')
    end

    it 'sets paid_at when auto-transition to paid' do
      record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 1000, balance: 0, due_date: Date.current, status: 'pending', month: 1, year: 2024, paid_at: nil)
      record.valid?
      expect(record.paid_at).to be_within(1.second).of(Time.current)
    end
  end

  describe 'scopes' do
    before do
      @unit2 = property.units.create(unit_number: '102', rent_amount: 1500, deposit_amount: 3000, occupancy_status: 'occupied')
      @tenant2 = Tenant.create!(unit: @unit2, full_name: 'Jane Smith', phone: '555-7777', move_in_date: Date.current, lease_start: Date.current, lease_end: 1.year.from_now.to_date, status: 'active')
      @paid_record = RentRecord.create!(unit: @unit2, amount_due: 1500, amount_paid: 1500, balance: 0, due_date: Date.current, status: 'paid', month: 1, year: 2024)
      @overdue_record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: 1.week.ago, status: 'overdue', month: 1, year: 2024)
    end

    it '.overdue returns only overdue records' do
      expect(RentRecord.overdue).to eq([@overdue_record])
    end

    it '.paid returns only paid records' do
      expect(RentRecord.paid).to eq([@paid_record])
    end

    it '.for_tenant filters by tenant' do
      rec = RentRecord.create!(unit: @unit2, amount_due: 1500, amount_paid: 0, balance: 1500, due_date: Date.current, status: 'pending', month: 2, year: 2024, tenant: @tenant2)
      expect(RentRecord.for_tenant(@tenant2.id)).to include(rec)
    end

    it '.by_month_year filters correctly' do
      rec = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 3, year: 2025)
      expect(RentRecord.by_month_year(3, 2025)).to include(rec)
    end
  end

  describe 'JSON methods' do
    it 'tenant_full_name returns tenant full_name' do
      record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 1, year: 2024, tenant: tenant)
      expect(record.tenant_full_name).to eq('John Doe')
    end

    it 'tenant_phone returns tenant phone' do
      record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 1, year: 2024, tenant: tenant)
      expect(record.tenant_phone).to eq('555-1234')
    end

    it 'returns nil for tenant methods when no tenant' do
      record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 1, year: 2024)
      expect(record.tenant_full_name).to be_nil
      expect(record.tenant_phone).to be_nil
    end
  end

  describe '#days_overdue' do
    it 'returns number of days overdue' do
      record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: 5.days.ago, status: 'overdue', month: 1, year: 2024)
      expect(record.days_overdue).to eq(5)
    end

    it 'returns 0 for non-overdue' do
      record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 1, year: 2024)
      expect(record.days_overdue).to eq(0)
    end
  end

  describe '.mark_all_overdue!' do
    it 'marks pending records past due as overdue' do
      pending_record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: 1.week.ago, status: 'pending', month: 1, year: 2024)
      expect { RentRecord.mark_all_overdue! }.to change { pending_record.reload.status }.from('pending').to('overdue')
    end

    it 'does not affect already paid records' do
      paid_record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 1000, balance: 0, due_date: 1.week.ago, status: 'paid', month: 1, year: 2024)
      expect { RentRecord.mark_all_overdue! }.not_to change { paid_record.reload.status }
    end
  end
end

  describe 'validations' do
    context 'amount_due' do
      it 'is invalid without amount_due' do
        record = RentRecord.new(unit: unit, amount_due: nil, amount_paid: 0, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        expect(record).not_to be_valid
        expect(record.errors[:amount_due]).to include("can't be blank")
      end
      it 'is invalid when negative' do
        record = RentRecord.new(unit: unit, amount_due: -100, amount_paid: 0, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        expect(record).not_to be_valid
      end
      it 'is valid when zero' do
        record = RentRecord.new(unit: unit, amount_due: 0, amount_paid: 0, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        expect(record).to be_valid
      end
    end

    context 'amount_paid' do
      it 'is invalid without amount_paid' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: nil, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        expect(record).not_to be_valid
        expect(record.errors[:amount_paid]).to include("can't be blank")
      end
      it 'is invalid when negative' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: -100, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        expect(record).not_to be_valid
      end
    end

    context 'balance' do
      it 'is invalid without balance' do
        record = RentRecord.new(unit: unit, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        record.balance = nil
        record.amount_due = 1000
        record.amount_paid = 0
        expect(record).not_to be_valid
        expect(record.errors[:balance]).to include("can't be blank")
      end
      it 'is invalid when negative' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 0, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        record.balance = -100
        expect(record).not_to be_valid
      end
    end

    context 'due_date' do
      it 'is invalid without due_date' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, month: 1, year: 2024, status: 'pending')
        record.due_date = nil
        expect(record).not_to be_valid
        expect(record.errors[:due_date]).to include("can't be blank")
      end
    end

    context 'status' do
      it 'is invalid without status' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, month: 1, year: 2024)
        record.status = nil
        expect(record).not_to be_valid
        expect(record.errors[:status]).to include("is not included in the list")
      end
      it 'is invalid with status not in the list' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'invalid', month: 1, year: 2024)
        expect(record).not_to be_valid
        expect(record.errors[:status]).to include("is not included in the list")
      end
      it 'is valid with status pending' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        expect(record).to be_valid
      end
      it 'is valid with status unpaid' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'unpaid', month: 1, year: 2024)
        expect(record).to be_valid
      end
      it 'is valid with status paid' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 1000, balance: 0, due_date: Date.current, status: 'paid', month: 1, year: 2024)
        expect(record).to be_valid
      end
      it 'is valid with status partial' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 500, balance: 500, due_date: Date.current, status: 'partial', month: 1, year: 2024)
        expect(record).to be_valid
      end
      it 'is valid with status overdue' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'overdue', month: 1, year: 2024)
        expect(record).to be_valid
      end

      it 'is valid with status waived' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 500, balance: 500, due_date: Date.current, status: 'waived', month: 1, year: 2024)
        expect(record).to be_valid
      end
     end

    context 'month' do
      it 'is invalid without month' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: nil, year: 2024)
        expect(record).not_to be_valid
        expect(record.errors[:month]).to include("can't be blank")
      end
      it 'is invalid when less than 1' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 0, year: 2024)
        expect(record).not_to be_valid
      end
      it 'is invalid when greater than 12' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 13, year: 2024)
        expect(record).not_to be_valid
      end
    end

    context 'year' do
      it 'is invalid without year' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 1, year: nil)
        expect(record).not_to be_valid
        expect(record.errors[:year]).to include("can't be blank")
      end
      it 'is invalid when less than 2000' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 0, balance: 1000, due_date: Date.current, status: 'pending', month: 1, year: 1999)
        expect(record).not_to be_valid
      end
    end

    context 'amount_paid vs amount_due' do
      it 'is invalid when amount_paid exceeds amount_due' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 1500, balance: 0, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        expect(record).not_to be_valid
        expect(record.errors[:amount_paid]).to include("cannot exceed amount due")
      end
    end

    context 'balance consistency' do
      it 'is invalid when balance does not match amount_due minus amount_paid' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 300, balance: 200, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        expect(record).not_to be_valid
        expect(record.errors[:balance]).to include("must be consistent with amount due and amount paid")
      end
    end
  end

  describe 'callbacks' do
    context '#calculate_balance' do
      it 'automatically calculates balance before validation' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 400, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        record.valid?
        expect(record.balance).to eq(600)
      end
    end

    context '#set_paid_at' do
      it 'sets paid_at to current time when status is paid and paid_at is nil' do
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 1000, due_date: Date.current, status: 'paid', month: 1, year: 2024, paid_at: nil)
        expect { record.save }.to change { record.paid_at }.from(nil).to(be_within(1.second).of(Time.current))
      end
      it 'does not change paid_at when status is paid and paid_at is already set' do
        paid_time = 1.day.ago
        record = RentRecord.new(unit: unit, amount_due: 1000, amount_paid: 1000, due_date: Date.current, status: 'paid', month: 1, year: 2024, paid_at: paid_time)
        record.save
        expect(record.paid_at).to be_within(1.second).of(paid_time)
      end
    end
  end

  describe 'rent payment scenarios' do
    context 'full payment' do
      it 'creates a paid record with zero balance' do
        record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 1000, due_date: Date.current, status: 'paid', month: 1, year: 2024)
        expect(record.balance).to eq(0)
        expect(record.status).to eq('paid')
      end
    end
    context 'partial payment' do
      it 'creates a partial record with positive balance' do
        record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 600, due_date: Date.current, status: 'partial', month: 1, year: 2024)
        expect(record.balance).to eq(400)
        expect(record.status).to eq('partial')
      end
    end
    context 'zero payment' do
      it 'creates a pending record with full balance' do
        record = RentRecord.create!(unit: unit, amount_due: 1000, amount_paid: 0, due_date: Date.current, status: 'pending', month: 1, year: 2024)
        expect(record.balance).to eq(1000)
        expect(record.status).to eq('pending')
      end
    end
  end
end
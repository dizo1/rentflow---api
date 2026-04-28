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

  describe 'associations' do
    it 'belongs to a unit' do
      association = described_class.reflect_on_association(:unit)
      expect(association.macro).to eq(:belongs_to)
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
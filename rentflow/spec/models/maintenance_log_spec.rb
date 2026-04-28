require 'rails_helper'

RSpec.describe MaintenanceLog, type: :model do
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
    context 'with valid attributes' do
      it 'is valid' do
        log = MaintenanceLog.new(unit: unit, title: 'Fix leak', description: 'Kitchen sink leaking', cost: 150.50, status: 'pending')
        expect(log).to be_valid
      end
    end

    context 'title' do
      it 'is invalid without title' do
        log = MaintenanceLog.new(unit: unit, title: nil, description: 'Test', cost: 100, status: 'pending')
        expect(log).not_to be_valid
        expect(log.errors[:title]).to include("can't be blank")
      end
    end

    context 'description' do
      it 'is invalid without description' do
        log = MaintenanceLog.new(unit: unit, title: 'Test', description: nil, cost: 100, status: 'pending')
        expect(log).not_to be_valid
        expect(log.errors[:description]).to include("can't be blank")
      end
    end

    context 'cost' do
      it 'is invalid without cost' do
        log = MaintenanceLog.new(unit: unit, title: 'Test', description: 'Test', cost: nil, status: 'pending')
        expect(log).not_to be_valid
        expect(log.errors[:cost]).to include("can't be blank")
      end

      it 'is invalid with negative cost' do
        log = MaintenanceLog.new(unit: unit, title: 'Test', description: 'Test', cost: -50, status: 'pending')
        expect(log).not_to be_valid
      end
    end

    context 'status' do
      it 'is invalid without status' do
        log = MaintenanceLog.new(unit: unit, title: 'Test', description: 'Test', cost: 100, status: nil)
        expect(log).not_to be_valid
        expect(log.errors[:status]).to include("can't be blank")
      end

      it 'is invalid with invalid status' do
        log = MaintenanceLog.new(unit: unit, title: 'Test', description: 'Test', cost: 100, status: 'invalid_status')
        expect(log).not_to be_valid
        expect(log.errors[:status]).to include("is not included in the list")
      end
    end
  end

  describe 'enums' do
    it 'defines status enum values' do
      expect(described_class.statuses.keys).to match_array(%w[pending in_progress resolved cancelled])
    end
  end

  describe 'scopes' do
    let!(:pending_log) { MaintenanceLog.create(unit: unit, title: 'Fix 1', description: 'Desc 1', cost: 100, status: 'pending') }
    let!(:in_progress_log) { MaintenanceLog.create(unit: unit, title: 'Fix 2', description: 'Desc 2', cost: 200, status: 'in_progress') }
    let!(:resolved_log) { MaintenanceLog.create(unit: unit, title: 'Fix 3', description: 'Desc 3', cost: 300, status: 'resolved') }
    let!(:cancelled_log) { MaintenanceLog.create(unit: unit, title: 'Fix 4', description: 'Desc 4', cost: 400, status: 'cancelled') }

    describe '.pending' do
      it 'returns only pending maintenance logs' do
        expect(described_class.pending).to match_array([pending_log])
      end
    end

    describe '.in_progress' do
      it 'returns only in_progress maintenance logs' do
        expect(described_class.in_progress).to match_array([in_progress_log])
      end
    end

    describe '.resolved' do
      it 'returns only resolved maintenance logs' do
        expect(described_class.resolved).to match_array([resolved_log])
      end
    end

    describe '.cancelled' do
      it 'returns only cancelled maintenance logs' do
        expect(described_class.cancelled).to match_array([cancelled_log])
      end
    end
  end

  describe 'callbacks' do
    context '#set_resolved_at' do
      it 'sets resolved_at when status changes to resolved' do
        log = MaintenanceLog.create(unit: unit, title: 'Fix leak', description: 'Desc', cost: 100, status: 'pending')
        expect(log.resolved_at).to be_nil

        log.update(status: 'resolved')
        expect(log.resolved_at).to be_within(1.second).of(Time.current)
      end

      it 'does not change resolved_at if already set' do
        existing_time = 1.day.ago
        log = MaintenanceLog.create(unit: unit, title: 'Fix leak', description: 'Desc', cost: 100, status: 'pending', resolved_at: existing_time)

        log.update(status: 'resolved')
        expect(log.resolved_at).to be_within(1.second).of(existing_time)
      end

      it 'does not set resolved_at for other status changes' do
        log = MaintenanceLog.create(unit: unit, title: 'Fix leak', description: 'Desc', cost: 100, status: 'pending')
        log.update(status: 'in_progress')
        expect(log.resolved_at).to be_nil
      end
    end
  end

  describe 'maintenance workflow' do
    let(:log) { MaintenanceLog.create(unit: unit, title: 'Fix leak', description: 'Kitchen sink leaking', cost: 100.00, status: 'pending') }

    it 'can transition from pending to in_progress' do
      log.update(status: 'in_progress')
      expect(log.status).to eq('in_progress')
      expect(log.resolved_at).to be_nil
    end

    it 'can transition from in_progress to resolved' do
      log.update(status: 'in_progress')
      log.update(status: 'resolved')
      expect(log.status).to eq('resolved')
      expect(log.resolved_at).to be_within(1.second).of(Time.current)
    end

    it 'can be cancelled' do
      log.update(status: 'cancelled')
      expect(log.status).to eq('cancelled')
      expect(log.resolved_at).to be_nil
    end
  end
end
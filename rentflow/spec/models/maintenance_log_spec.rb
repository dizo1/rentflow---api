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

     context 'priority' do
       it 'has a default priority of medium' do
         log = MaintenanceLog.new(
           unit: unit,
           title: 'Test',
           description: 'Desc',
           cost: 100,
           status: 'pending',
           reported_date: Date.current
         )
         log.valid?
         expect(log.priority).to eq('medium')
       end

       it 'accepts valid priority values' do
         %w[low medium high urgent].each do |p|
           log = MaintenanceLog.new(
             unit: unit,
             title: 'Test',
             description: 'Desc',
             cost: 100,
             status: 'pending',
             priority: p,
             reported_date: Date.current
           )
           expect(log).to be_valid, "Expected #{p} to be valid"
         end
       end

       it 'is invalid with an invalid priority' do
         log = MaintenanceLog.new(
           unit: unit,
           title: 'Test',
           description: 'Desc',
           cost: 100,
           status: 'pending',
           priority: 'invalid',
           reported_date: Date.current
         )
         expect(log).not_to be_valid
         expect(log.errors[:priority]).to include("is not included in the list")
       end
     end

     context 'reported_date' do
       it 'is invalid without reported_date' do
         log = MaintenanceLog.new(
           unit: unit,
           title: 'Test',
           description: 'Desc',
           cost: 100,
           status: 'pending',
           priority: 'medium',
           reported_date: nil
         )
         expect(log).not_to be_valid
         expect(log.errors[:reported_date]).to include("can't be blank")
       end
     end
   end

  describe 'enums' do
    it 'defines status enum values' do
      expect(described_class.statuses.keys).to match_array(%w[pending in_progress resolved cancelled])
    end
  end

  describe 'scopes' do
    let!(:pending_log) { MaintenanceLog.create(unit: unit, title: 'Fix 1', description: 'Desc 1', cost: 100, status: 'pending', priority: 'medium', reported_date: Date.current) }
    let!(:in_progress_log) { MaintenanceLog.create(unit: unit, title: 'Fix 2', description: 'Desc 2', cost: 200, status: 'in_progress', priority: 'medium', reported_date: Date.current) }
    let!(:resolved_log) { MaintenanceLog.create(unit: unit, title: 'Fix 3', description: 'Desc 3', cost: 300, status: 'resolved', priority: 'medium', reported_date: Date.current) }
    let!(:cancelled_log) { MaintenanceLog.create(unit: unit, title: 'Fix 4', description: 'Desc 4', cost: 400, status: 'cancelled', priority: 'medium', reported_date: Date.current) }

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

    describe '.by_priority' do
      it 'filters logs by priority' do
        high_log = MaintenanceLog.create!(unit: unit, title: 'Urgent', description: 'Leak', cost: 500, status: 'pending', priority: 'high', reported_date: Date.current)
        low_log = MaintenanceLog.create!(unit: unit, title: 'Minor', description: 'Scratch', cost: 50, status: 'pending', priority: 'low', reported_date: Date.current)
        results = MaintenanceLog.by_priority('high')
        expect(results).to include(high_log)
        expect(results).not_to include(low_log, pending_log)
      end
    end

    describe '.open' do
      it 'returns pending and in_progress logs' do
        expect(described_class.open).to match_array([pending_log, in_progress_log])
      end
    end

    describe '.closed' do
      it 'returns resolved and cancelled logs' do
        expect(described_class.closed).to match_array([resolved_log, cancelled_log])
      end
    end
  end

  describe 'callbacks' do
    context '#set_resolved_at' do
      it 'sets resolved_at when status changes to resolved' do
        log = MaintenanceLog.create(unit: unit, title: 'Fix leak', description: 'Desc', cost: 100, status: 'pending', priority: 'medium', reported_date: Date.current)
        expect(log.resolved_at).to be_nil

        log.update(status: 'resolved')
        expect(log.resolved_at).to be_within(1.second).of(Time.current)
      end

      it 'does not change resolved_at if already set' do
        existing_time = 1.day.ago
        log = MaintenanceLog.create(unit: unit, title: 'Fix leak', description: 'Desc', cost: 100, status: 'pending', priority: 'medium', reported_date: Date.current, resolved_at: existing_time)

        log.update(status: 'resolved')
        expect(log.resolved_at).to be_within(1.second).of(existing_time)
      end

      it 'does not set resolved_at for other status changes' do
        log = MaintenanceLog.create(unit: unit, title: 'Fix leak', description: 'Desc', cost: 100, status: 'pending', priority: 'medium', reported_date: Date.current)
        log.update(status: 'in_progress')
        expect(log.resolved_at).to be_nil
      end
    end
  end

  describe 'maintenance workflow' do
    let(:log) { MaintenanceLog.create(unit: unit, title: 'Fix leak', description: 'Kitchen sink leaking', cost: 100.00, status: 'pending', priority: 'medium', reported_date: Date.current) }

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

  describe 'priority enum' do
    it { should define_enum_for(:priority).with_values(['low', 'medium', 'high', 'urgent']) }

    it 'has correct priority values' do
      expect(MaintenanceLog.priorities.keys).to match_array(%w[low medium high urgent])
    end
  end

  describe 'callbacks' do
    describe '#set_default_priority' do
      it 'sets priority to medium on create if not provided' do
        log = MaintenanceLog.create!(
          unit: unit,
          title: 'Test',
          description: 'Test description',
          cost: 100,
          status: 'pending',
          reported_date: Date.current
          # priority omitted
        )
        expect(log.priority).to eq('medium')
      end
    end

    describe '#clear_resolved_at' do
      it 'clears resolved_at when status changes from resolved to something else' do
        log = MaintenanceLog.create!(
          unit: unit,
          title: 'Test',
          description: 'desc',
          cost: 100,
          status: 'resolved',
          priority: 'medium',
          reported_date: Date.current
        )
        expect(log.resolved_at).to be_present
        log.update!(status: 'in_progress')
        expect(log.reload.resolved_at).to be_nil
      end
    end
  end

  describe 'instance methods' do
    describe '#mark_in_progress!' do
      it 'updates status to in_progress' do
        log = MaintenanceLog.create!(unit: unit, title: 'Test', description: 'd', cost: 100, status: 'pending', priority: 'medium', reported_date: Date.current)
        log.mark_in_progress!
        expect(log.reload.status).to eq('in_progress')
      end
    end

    describe '#mark_resolved!' do
      it 'updates status to resolved and sets resolved_at' do
        log = MaintenanceLog.create!(unit: unit, title: 'Test', description: 'd', cost: 100, status: 'pending', priority: 'medium', reported_date: Date.current)
        log.mark_resolved!
        expect(log.reload.status).to eq('resolved')
        expect(log.resolved_at).to be_within(1.second).of(Time.current)
      end
    end

    describe '#cancel!' do
      it 'updates status to cancelled' do
        log = MaintenanceLog.create!(unit: unit, title: 'Test', description: 'd', cost: 100, status: 'pending', priority: 'medium', reported_date: Date.current)
        log.cancel!
        expect(log.reload.status).to eq('cancelled')
        expect(log.resolved_at).to be_nil
      end
    end

    describe '#completed?' do
      it 'returns true for resolved status' do
        log = MaintenanceLog.create!(unit: unit, title: 'Test', description: 'd', cost: 100, status: 'resolved', priority: 'medium', reported_date: Date.current)
        expect(log.completed?).to be true
      end

      it 'returns true for cancelled status' do
        log = MaintenanceLog.create!(unit: unit, title: 'Test', description: 'd', cost: 100, status: 'cancelled', priority: 'medium', reported_date: Date.current)
        expect(log.completed?).to be true
      end

      it 'returns false for pending' do
        log = MaintenanceLog.create!(unit: unit, title: 'Test', description: 'd', cost: 100, status: 'pending', priority: 'medium', reported_date: Date.current)
        expect(log.completed?).to be false
      end
    end

    describe '#days_to_resolve' do
      it 'returns number of days between reported_date and resolved_at' do
        log = MaintenanceLog.create!(
          unit: unit,
          title: 'Test',
          description: 'd',
          cost: 100,
          status: 'resolved',
          priority: 'medium',
          reported_date: 5.days.ago.to_date,
          resolved_at: 2.days.ago
        )
        expect(log.days_to_resolve).to eq(3)
      end

      it 'returns nil if not resolved' do
        log = MaintenanceLog.create!(
          unit: unit,
          title: 'Test',
          description: 'd',
          cost: 100,
          status: 'pending',
          priority: 'medium',
          reported_date: Date.current
        )
        expect(log.days_to_resolve).to be_nil
      end
    end

    describe '#summary' do
      it 'returns hash with required keys' do
        log = MaintenanceLog.create!(
          unit: unit,
          title: 'Test',
          description: 'd',
          cost: 100,
          status: 'resolved',
          priority: 'high',
          reported_date: Date.current,
          resolved_at: 1.day.ago,
          assigned_to: 'Tech A'
        )
        summary = log.summary
        expect(summary.keys).to include(:id, :title, :status, :priority, :cost, :days_to_resolve, :reported_date, :resolved_at, :assigned_to)
      end
    end
  end

      it 'returns true for cancelled status' do
        log = MaintenanceLog.create!(unit: unit, title: 'Test', description: 'd', cost: 100, status: 'cancelled', priority: 'medium', reported_date: Date.current)
        expect(log.completed?).to be true
      end

      it 'returns false for pending status' do
        log = MaintenanceLog.create!(unit: unit, title: 'Test', description: 'd', cost: 100, status: 'pending', priority: 'medium', reported_date: Date.current)
        expect(log.completed?).to be false
      end
    end

    describe '#days_to_resolve' do
      it 'returns number of days between reported_date and resolved_at' do
        log = MaintenanceLog.create!(
          unit: unit,
          title: 'Test',
          description: 'd',
          cost: 100,
          status: 'resolved',
          priority: 'medium',
          reported_date: 5.days.ago.to_date,
          resolved_at: 2.days.ago
        )
        expect(log.days_to_resolve).to eq(3)
      end

      it 'returns nil if not resolved yet' do
        log = MaintenanceLog.create!(
          unit: unit,
          title: 'Test',
          description: 'd',
          cost: 100,
          status: 'pending',
          priority: 'medium',
          reported_date: Date.current
        )
        expect(log.days_to_resolve).to be_nil
      end
    end

    describe '#summary' do
      it 'returns hash with required keys' do
        log = MaintenanceLog.create!(
          unit: unit,
          title: 'Test',
          description: 'd',
          cost: 100,
          status: 'resolved',
          priority: 'high',
          reported_date: Date.current,
          resolved_at: 1.day.ago,
          assigned_to: 'Tech A'
        )
        summary = log.summary
        expect(summary.keys).to include(:id, :title, :status, :priority, :cost, :days_to_resolve, :reported_date, :resolved_at, :assigned_to)
      end
    end
  end
end
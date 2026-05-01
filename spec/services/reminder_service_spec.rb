require 'rails_helper'

RSpec.describe ReminderService, type: :service do
  let(:user) { User.create(email: 'user@example.com', password: 'password123', name: 'Test User') }
  let(:property) { Property.create!(user: user, name: 'Test Property', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 2) }
  let(:unit) { property.units.create!(unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied') }
  let(:tenant) do
    unit.create_tenant!(full_name: 'John Doe', phone: '1234567890', email: 'john@example.com', move_in_date: Date.current, lease_start: Date.current, lease_end: 1.year.from_now, status: 'active')
  end
  let(:service) { ReminderService.new(user) }

  describe '#call' do
    it 'detects rent due triggers' do
      rent_record = unit.rent_records.create!(
        amount_due: 1200,
        amount_paid: 0,
        balance: 1200,
        due_date: Date.tomorrow,
        status: 'pending',
        month: Date.tomorrow.month,
        year: Date.tomorrow.year,
        tenant: tenant
      )

      expect { service.call }.to change(Reminder, :count).by(1)

      reminder = Reminder.last
      expect(reminder.reminder_type).to eq('rent_due')
      expect(reminder.tenant).to eq(tenant)
      expect(reminder.unit).to eq(unit)
      expect(reminder.rent_record).to eq(rent_record)
      expect(reminder.channel).to eq('sms')
      expect(reminder.status).to eq('pending')
    end

    it 'detects rent overdue triggers' do
      rent_record = unit.rent_records.create!(
        amount_due: 1200,
        amount_paid: 0,
        balance: 1200,
        due_date: Date.yesterday,
        status: 'overdue',
        month: Date.yesterday.month,
        year: Date.yesterday.year,
        tenant: tenant
      )

      expect { service.call }.to change(Reminder, :count).by(1)

      reminder = Reminder.last
      expect(reminder.reminder_type).to eq('rent_overdue')
      expect(reminder.message).to include('overdue')
    end

    it 'detects lease expiry triggers' do
      tenant.update!(lease_end: 5.days.from_now)

      expect { service.call }.to change(Reminder, :count).by(1)

      reminder = Reminder.last
      expect(reminder.reminder_type).to eq('lease_expiry')
      expect(reminder.message).to include('ends on')
    end

    it 'detects maintenance followup triggers' do
      # Ensure tenant is created
      tenant

      maintenance_log = unit.maintenance_logs.create!(
        title: 'Fix leak',
        description: 'Kitchen sink leaking',
        cost: 150,
        status: 'pending',
        priority: 'medium',
        reported_date: 4.days.ago.to_date
      )

      expect { service.call }.to change(Reminder, :count).by(1)

      reminder = Reminder.last
      expect(reminder.reminder_type).to eq('maintenance_followup')
      expect(reminder.maintenance_log).to eq(maintenance_log)
    end

    it 'creates notifications for the landlord' do
      rent_record = unit.rent_records.create!(
        amount_due: 1200,
        amount_paid: 0,
        balance: 1200,
        due_date: Date.tomorrow,
        status: 'pending',
        month: Date.tomorrow.month,
        year: Date.tomorrow.year,
        tenant: tenant
      )

      expect { service.call }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.user).to eq(user)
      expect(notification.notification_type).to eq('reminder_sent')
    end

    it 'does not create duplicate reminders for the same trigger' do
      rent_record = unit.rent_records.create!(
        amount_due: 1200,
        amount_paid: 0,
        balance: 1200,
        due_date: Date.tomorrow,
        status: 'pending',
        month: Date.tomorrow.month,
        year: Date.tomorrow.year,
        tenant: tenant
      )

      service.call
      expect { service.call }.to_not change(Reminder, :count)
    end
  end
end
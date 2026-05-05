require 'rails_helper'

RSpec.describe Reminder, type: :model do
  let(:user) { User.create(email: 'user@example.com', password: 'password123', name: 'Test User') }
  let(:property) { Property.create!(user: user, name: 'Test Property', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 2) }
  let(:unit) { property.units.create!(unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied') }
  let(:tenant) { unit.create_tenant!(full_name: 'John Doe', phone: '1234567890', email: 'john@example.com', move_in_date: Date.current, lease_start: Date.current, lease_end: 1.year.from_now, status: 'active') }

  describe 'associations' do
    it 'belongs to tenant' do
      association = described_class.reflect_on_association(:tenant)
      expect(association.macro).to eq(:belongs_to)
    end
    
    it 'belongs to unit' do
      association = described_class.reflect_on_association(:unit)
      expect(association.macro).to eq(:belongs_to)
    end
    
    it 'belongs to rent_record' do
      association = described_class.reflect_on_association(:rent_record)
      expect(association.macro).to eq(:belongs_to)
    end
    
    it 'belongs to maintenance_log' do
      association = described_class.reflect_on_association(:maintenance_log)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'enums' do
    it 'defines reminder_type enum values' do
      expect(described_class.reminder_types.keys).to match_array(%w[rent_due rent_overdue payment_confirmation lease_expiry maintenance_followup maintenance_resolution manual_followup])
    end
    
    it 'defines channel enum values' do
      expect(described_class.channels.keys).to match_array(%w[sms notification])
    end
    
    it 'defines status enum values' do
      expect(described_class.statuses.keys).to match_array(%w[pending scheduled sent failed cancelled retried])
    end
  end

  describe 'validations' do
    context 'with valid attributes' do
      it 'is valid' do
        reminder = Reminder.new(
          tenant: tenant,
          unit: unit,
          reminder_type: 'rent_due',
          message: 'Test reminder',
          channel: 'sms',
          status: 'pending',
          scheduled_for: Time.current
        )
        expect(reminder).to be_valid
      end
    end

    context 'message' do
      it 'is invalid without message' do
        reminder = Reminder.new(
          tenant: tenant,
          unit: unit,
          reminder_type: 'rent_due',
          channel: 'sms',
          status: 'pending',
          scheduled_for: Time.current
        )
        expect(reminder).not_to be_valid
        expect(reminder.errors[:message]).to include("can't be blank")
      end
    end

    context 'scheduled_for' do
      it 'is invalid without scheduled_for' do
        reminder = Reminder.new(
          tenant: tenant,
          unit: unit,
          reminder_type: 'rent_due',
          message: 'Test reminder',
          channel: 'sms',
          status: 'pending'
        )
        expect(reminder).not_to be_valid
        expect(reminder.errors[:scheduled_for]).to include("can't be blank")
      end
    end

    context 'reminder_type' do
      it 'is invalid without reminder_type' do
        reminder = Reminder.new(
          tenant: tenant,
          unit: unit,
          message: 'Test reminder',
          channel: 'sms',
          status: 'pending',
          scheduled_for: Time.current
        )
        expect(reminder).not_to be_valid
        expect(reminder.errors[:reminder_type]).to include("can't be blank")
      end
    end

    context 'channel' do
      it 'is invalid without channel' do
        reminder = Reminder.new(
          tenant: tenant,
          unit: unit,
            message: 'Test reminder',
          reminder_type: 'rent_due',
          status: 'pending',
          scheduled_for: Time.current
        )
        expect(reminder).not_to be_valid
        expect(reminder.errors[:channel]).to include("can't be blank")
      end
    end

    context 'status' do
      it 'is invalid without status' do
        reminder = Reminder.new(
          tenant: tenant,
          unit: unit,
          reminder_type: 'rent_due',
          message: 'Test reminder',
          channel: 'sms',
          scheduled_for: Time.current
        )
        expect(reminder).not_to be_valid
        expect(reminder.errors[:status]).to include("can't be blank")
      end
    end
  end

  describe 'scopes' do
    describe '.for_user' do
      it 'returns reminders for the given user' do
        # Create a rent record for testing
        rent_record = unit.rent_records.create!(amount_due: 1200, amount_paid: 0, balance: 1200, due_date: Date.tomorrow, status: 'pending', month: Date.tomorrow.month, year: Date.tomorrow.year)

        reminder = Reminder.create!(
          tenant: tenant,
          unit: unit,
          rent_record: rent_record,
          reminder_type: 'rent_due',
          message: 'Test reminder',
          channel: 'sms',
          status: 'pending',
          scheduled_for: Time.current
        )

        expect(Reminder.for_user(user.id)).to include(reminder)
      end

      it 'does not return reminders for other users' do
        other_user = User.create(email: 'other@example.com', password: 'password123')
        other_property = Property.create!(user: other_user, name: 'Other Property', address: '456 Ave', property_type: 'house', status: 'occupied', total_units: 2)
        other_unit = other_property.units.create!(unit_number: '201', rent_amount: 2000, deposit_amount: 4000, occupancy_status: 'occupied')
        other_tenant = other_unit.create_tenant!(full_name: 'Jane Smith', phone: '0987654321', email: 'jane@example.com', move_in_date: Date.current, lease_start: Date.current, lease_end: 1.year.from_now, status: 'active')
        other_rent_record = other_unit.rent_records.create!(amount_due: 2000, amount_paid: 0, balance: 2000, due_date: Date.tomorrow, status: 'pending', month: Date.tomorrow.month, year: Date.tomorrow.year)

        other_reminder = Reminder.create!(
          tenant: other_tenant,
          unit: other_unit,
          rent_record: other_rent_record,
          reminder_type: 'rent_due',
          message: 'Other reminder',
          channel: 'sms',
          status: 'pending',
          scheduled_for: Time.current
        )

        expect(Reminder.for_user(user.id)).not_to include(other_reminder)
      end
    end
  end
end
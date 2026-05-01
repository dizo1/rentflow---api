require 'rails_helper'

RSpec.describe Api::V1::RemindersController, type: :controller do
  let!(:user) { User.create(email: 'user@example.com', password: 'password123', name: 'Test User') }
  let!(:other_user) { User.create(email: 'other@example.com', password: 'password123') }
  let!(:user_token) { user.generate_jwt }
  let!(:property) { Property.create!(user: user, name: 'Test Property', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 2) }
  let!(:unit) { property.units.create!(unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied') }
  let!(:tenant) { unit.create_tenant!(full_name: 'John Doe', phone: '1234567890', email: 'john@example.com', move_in_date: Date.current, lease_start: Date.current, lease_end: 1.year.from_now, status: 'active') }
  let!(:rent_record) { unit.rent_records.create!(amount_due: 1200, amount_paid: 0, balance: 1200, due_date: Date.tomorrow, status: 'pending', month: Date.tomorrow.month, year: Date.tomorrow.year) }

  before do
    request.headers['Authorization'] = "Bearer #{user_token}"
  end

  describe 'GET #index' do
    it 'returns reminders for the authenticated user' do
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

      get :index

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data'].length).to eq(1)
      expect(json['data'].first['id']).to eq(reminder.id)
    end

    it 'does not return reminders for other users' do
      other_property = Property.create!(user: other_user, name: 'Other Property', address: '456 Ave', property_type: 'house', status: 'occupied', total_units: 2)
      other_unit = other_property.units.create!(unit_number: '201', rent_amount: 2000, deposit_amount: 4000, occupancy_status: 'occupied')
      other_tenant = other_unit.create_tenant!(full_name: 'Jane Smith', phone: '0987654321', email: 'jane@example.com', move_in_date: Date.current, lease_start: Date.current, lease_end: 1.year.from_now, status: 'active')
      other_reminder = Reminder.create!(
        tenant: other_tenant,
        unit: other_unit,
        reminder_type: 'rent_due',
        message: 'Other reminder',
        channel: 'sms',
        status: 'pending',
        scheduled_for: Time.current
      )

      get :index

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data'].length).to eq(0)
    end
  end

  describe 'GET #show' do
    it 'returns the reminder if it belongs to the authenticated user' do
      reminder = Reminder.create!(
        tenant: tenant,
        unit: unit,
        reminder_type: 'rent_due',
        message: 'Test reminder',
        channel: 'sms',
        status: 'pending',
        scheduled_for: Time.current
      )

      get :show, params: { id: reminder.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['id']).to eq(reminder.id)
    end

    it 'returns not found if reminder does not belong to the authenticated user' do
      other_property = Property.create!(user: other_user, name: 'Other Property', address: '456 Ave', property_type: 'house', status: 'occupied', total_units: 2)
      other_unit = other_property.units.create!(unit_number: '201', rent_amount: 2000, deposit_amount: 4000, occupancy_status: 'occupied')
      other_tenant = other_unit.create_tenant!(full_name: 'Jane Smith', phone: '0987654321', email: 'jane@example.com', move_in_date: Date.current, lease_start: Date.current, lease_end: 1.year.from_now, status: 'active')
      other_reminder = Reminder.create!(
        tenant: other_tenant,
        unit: other_unit,
        reminder_type: 'rent_due',
        message: 'Other reminder',
        channel: 'sms',
        status: 'pending',
        scheduled_for: Time.current
      )

      get :show, params: { id: other_reminder.id }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    it 'creates a reminder for the authenticated user' do
      reminder_params = {
        tenant_id: tenant.id,
        unit_id: unit.id,
        rent_record_id: rent_record.id,
        reminder_type: 'rent_due',
        message: 'New reminder',
        channel: 'sms',
        status: 'pending',
        scheduled_for: Time.current
      }

      expect {
        post :create, params: { reminder: reminder_params }
      }.to change(Reminder, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['message']).to eq('New reminder')
    end

    it 'returns error for invalid reminder data' do
      reminder_params = {
        tenant_id: tenant.id,
        unit_id: unit.id,
        # missing message
        reminder_type: 'rent_due',
        channel: 'sms',
        status: 'pending',
        scheduled_for: Time.current
      }

      post :create, params: { reminder: reminder_params }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['success']).to be false
      expect(json['error']).to include("can't be blank")
    end
  end

  describe 'PATCH #update' do
    it 'updates the reminder if it belongs to the authenticated user' do
      reminder = Reminder.create!(
        tenant: tenant,
        unit: unit,
        reminder_type: 'rent_due',
        message: 'Original message',
        channel: 'sms',
        status: 'pending',
        scheduled_for: Time.current
      )

      update_params = { message: 'Updated message' }

      patch :update, params: { id: reminder.id, reminder: update_params }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['message']).to eq('Updated message')
      expect(reminder.reload.message).to eq('Updated message')
    end

    it 'returns not found if reminder does not belong to the authenticated user' do
      other_property = Property.create!(user: other_user, name: 'Other Property', address: '456 Ave', property_type: 'house', status: 'occupied', total_units: 2)
      other_unit = other_property.units.create!(unit_number: '201', rent_amount: 2000, deposit_amount: 4000, occupancy_status: 'occupied')
      other_tenant = other_unit.create_tenant!(full_name: 'Jane Smith', phone: '0987654321', email: 'jane@example.com', move_in_date: Date.current, lease_start: Date.current, lease_end: 1.year.from_now, status: 'active')
      other_reminder = Reminder.create!(
        tenant: other_tenant,
        unit: other_unit,
        reminder_type: 'rent_due',
        message: 'Other reminder',
        channel: 'sms',
        status: 'pending',
        scheduled_for: Time.current
      )

      patch :update, params: { id: other_reminder.id, reminder: { message: 'Updated' } }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the reminder if it belongs to the authenticated user' do
      reminder = Reminder.create!(
        tenant: tenant,
        unit: unit,
        reminder_type: 'rent_due',
        message: 'Test reminder',
        channel: 'sms',
        status: 'pending',
        scheduled_for: Time.current
      )

      expect {
        delete :destroy, params: { id: reminder.id }
      }.to change(Reminder, :count).by(-1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end

    it 'returns not found if reminder does not belong to the authenticated user' do
      other_property = Property.create!(user: other_user, name: 'Other Property', address: '456 Ave', property_type: 'house', status: 'occupied', total_units: 2)
      other_unit = other_property.units.create!(unit_number: '201', rent_amount: 2000, deposit_amount: 4000, occupancy_status: 'occupied')
      other_tenant = other_unit.create_tenant!(full_name: 'Jane Smith', phone: '0987654321', email: 'jane@example.com', move_in_date: Date.current, lease_start: Date.current, lease_end: 1.year.from_now, status: 'active')
      other_reminder = Reminder.create!(
        tenant: other_tenant,
        unit: other_unit,
        reminder_type: 'rent_due',
        message: 'Other reminder',
        channel: 'sms',
        status: 'pending',
        scheduled_for: Time.current
      )

      delete :destroy, params: { id: other_reminder.id }

      expect(response).to have_http_status(:not_found)
    end
  end
end
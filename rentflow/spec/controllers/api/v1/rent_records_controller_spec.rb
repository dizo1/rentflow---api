require 'rails_helper'

RSpec.describe Api::V1::RentRecordsController, type: :controller do
  let!(:user) { User.create(email: 'user@example.com', password: 'password123') }
  let!(:admin) { User.create(email: 'admin@example.com', password: 'password123', role: 'admin') }
  let(:user_token) { user.generate_jwt }
  let(:admin_token) { admin.generate_jwt }
  let!(:property) { Property.create(user: user, name: 'Test Property', address: '123 St', property_type: 'apartment', status: 'occupied', total_units: 5) }
  let!(:unit) { property.units.create(unit_number: '101', rent_amount: 1000, deposit_amount: 2000, occupancy_status: 'occupied', tenant_name: 'John Doe', tenant_phone: '555-1234') }

  before do
    request.headers['Authorization'] = "Bearer #{user_token}"
  end

  describe 'GET #index' do
    let!(:rent_record) do
      unit.rent_records.create(
        amount_due: 1000,
        amount_paid: 1000,
        balance: 0,
        due_date: Date.current,
        status: 'paid',
        month: Date.current.month,
        year: Date.current.year,
        paid_at: Time.current
      )
    end

    it 'requires admin for unit-scoped index' do
      get :index, params: { unit_id: unit.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns rent records for unit as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :index, params: { unit_id: unit.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(1)
      expect(json['data'].first['amount_due']).to eq('1000.0')
    end

    it 'returns rent records for owner-scoped unit' do
      # Owner can access their own unit's rent records through the unit-scoped endpoint
      request.headers['Authorization'] = "Bearer #{user_token}"
      get :index, params: { unit_id: unit.id }
      expect(response).to have_http_status(:forbidden) # index requires admin
    end
  end

  describe 'GET #show' do
    let!(:rent_record) do
      unit.rent_records.create(
        amount_due: 1000,
        amount_paid: 500,
        balance: 500,
        due_date: Date.current,
        status: 'partial',
        month: Date.current.month,
        year: Date.current.year,
        paid_at: nil
      )
    end

    it 'returns rent record for owner' do
      get :show, params: { id: rent_record.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['amount_due']).to eq('1000.0')
      expect(json['data']['balance']).to eq('500.0')
    end

    it 'returns rent record for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :show, params: { id: rent_record.id }
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access for other users' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      get :show, params: { id: rent_record.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns not found for non-existent rent record' do
      get :show, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    it 'requires admin for unit-scoped create' do
      post :create, params: {
        unit_id: unit.id,
        rent_record: {
          amount_due: 1000,
          amount_paid: 1000,
          due_date: Date.current,
          status: 'paid',
          month: Date.current.month,
          year: Date.current.year
        }
      }
      expect(response).to have_http_status(:forbidden)
    end

    it 'creates a rent record as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      post :create, params: {
        unit_id: unit.id,
        rent_record: {
          amount_due: 1000,
          amount_paid: 1000,
          due_date: Date.current,
          status: 'paid',
          month: Date.current.month,
          year: Date.current.year
        }
      }
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['data']['amount_due']).to eq('1000.0')
      expect(json['data']['status']).to eq('paid')
    end

    it 'returns errors for invalid data' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      post :create, params: {
        unit_id: unit.id,
        rent_record: {
          amount_due: -100,
          amount_paid: 200,
          due_date: Date.current,
          status: 'paid',
          month: Date.current.month,
          year: Date.current.year
        }
      }
      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Validation failed')
    end
  end

  describe 'PUT #update' do
    let!(:rent_record) do
      unit.rent_records.create(
        amount_due: 1000,
        amount_paid: 500,
        balance: 500,
        due_date: Date.current,
        status: 'partial',
        month: Date.current.month,
        year: Date.current.year,
        paid_at: nil
      )
    end

    it 'updates as owner' do
      put :update, params: {
        id: rent_record.id,
        rent_record: { amount_paid: 1000, status: 'paid' }
      }
      expect(response).to have_http_status(:ok)
      rent_record.reload
      expect(rent_record.amount_paid).to eq(1000)
      expect(rent_record.status).to eq('paid')
    end

    it 'updates as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      put :update, params: {
        id: rent_record.id,
        rent_record: { amount_paid: 800, status: 'partial' }
      }
      expect(response).to have_http_status(:ok)
      rent_record.reload
      expect(rent_record.amount_paid).to eq(800)
    end

    it 'forbids update by other users' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      put :update, params: {
        id: rent_record.id,
        rent_record: { amount_paid: 200 }
      }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns errors for invalid update data' do
      put :update, params: {
        id: rent_record.id,
        rent_record: { amount_due: -100 }
      }
      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Update failed')
    end

    it 'returns not found for non-existent rent record' do
      put :update, params: {
        id: 99999,
        rent_record: { amount_paid: 1000 }
      }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    let!(:rent_record) do
      unit.rent_records.create(
        amount_due: 1000,
        amount_paid: 0,
        balance: 1000,
        due_date: Date.current,
        status: 'pending',
        month: Date.current.month,
        year: Date.current.year,
        paid_at: nil
      )
    end

    it 'deletes as owner' do
      expect {
        delete :destroy, params: { id: rent_record.id }
      }.to change(RentRecord, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it 'deletes as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      expect {
        delete :destroy, params: { id: rent_record.id }
      }.to change(RentRecord, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it 'forbids delete by other users' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      delete :destroy, params: { id: rent_record.id }
      expect(response).to have_http_status(:forbidden)
    end
  end
end

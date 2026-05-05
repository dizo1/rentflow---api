require 'rails_helper'

RSpec.describe Api::V1::MaintenanceLogsController, type: :controller do
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
    let!(:maintenance_log) do
      unit.maintenance_logs.create(
        title: 'Fix leak',
        description: 'Kitchen sink leaking badly',
        cost: 150.50,
        status: 'pending'
      )
    end

    it 'returns maintenance logs for unit as owner' do
      get :index, params: { unit_id: unit.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(1)
      expect(json['data'].first['title']).to eq('Fix leak')
      expect(json['data'].first['cost']).to eq('150.5')
    end

    it 'returns maintenance logs for unit as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :index, params: { unit_id: unit.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(1)
    end

    it 'returns not found for other users unit' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      get :index, params: { unit_id: unit.id }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for non-existent unit' do
      get :index, params: { unit_id: 99999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #show' do
    let!(:maintenance_log) do
      unit.maintenance_logs.create(
        title: 'Paint walls',
        description: 'Living room needs fresh paint',
        cost: 300.00,
        status: 'in_progress'
      )
    end

    it 'returns maintenance log for owner' do
      get :show, params: { id: maintenance_log.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['title']).to eq('Paint walls')
      expect(json['data']['status']).to eq('in_progress')
    end

    it 'returns maintenance log for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :show, params: { id: maintenance_log.id }
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access for other users' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      get :show, params: { id: maintenance_log.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns not found for non-existent maintenance log' do
      get :show, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    it 'creates a maintenance log as owner' do
      post :create, params: {
        unit_id: unit.id,
        maintenance_log: {
          title: 'Fix electrical outlet',
          description: 'Outlet in bedroom not working',
          cost: 75.00,
          status: 'pending'
        }
      }
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['data']['title']).to eq('Fix electrical outlet')
      expect(json['data']['cost']).to eq('75.0')
      expect(json['data']['status']).to eq('pending')
      expect(json['data']['resolved_at']).to be_nil
    end

    it 'creates a maintenance log as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      post :create, params: {
        unit_id: unit.id,
        maintenance_log: {
          title: 'Replace filter',
          description: 'HVAC filter needs replacement',
          cost: 50.00,
          status: 'resolved'
        }
      }
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['data']['status']).to eq('resolved')
      expect(json['data']['resolved_at']).to be_present
    end

    it 'returns errors for invalid data' do
      post :create, params: {
        unit_id: unit.id,
        maintenance_log: {
          title: '',
          description: 'Test',
          cost: -100,
          status: 'invalid_status'
        }
      }
      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Validation failed')
    end

    it 'returns not found for other users unit' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      post :create, params: {
        unit_id: unit.id,
        maintenance_log: {
          title: 'Test',
          description: 'Test',
          cost: 100,
          status: 'pending'
        }
      }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PUT #update' do
    let!(:maintenance_log) do
      unit.maintenance_logs.create(
        title: 'Fix leak',
        description: 'Kitchen sink leaking',
        cost: 150.00,
        status: 'pending'
      )
    end

    it 'updates maintenance log as owner' do
      put :update, params: {
        id: maintenance_log.id,
        maintenance_log: {
          status: 'in_progress',
          cost: 200.00
        }
      }
      expect(response).to have_http_status(:ok)
      maintenance_log.reload
      expect(maintenance_log.status).to eq('in_progress')
      expect(maintenance_log.cost).to eq(200.00)
      expect(maintenance_log.resolved_at).to be_nil
    end

    it 'updates status to resolved and sets resolved_at' do
      put :update, params: {
        id: maintenance_log.id,
        maintenance_log: { status: 'resolved' }
      }
      expect(response).to have_http_status(:ok)
      maintenance_log.reload
      expect(maintenance_log.status).to eq('resolved')
      expect(maintenance_log.resolved_at).to be_within(1.second).of(Time.current)
    end

    it 'updates as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      put :update, params: {
        id: maintenance_log.id,
        maintenance_log: { status: 'cancelled' }
      }
      expect(response).to have_http_status(:ok)
      maintenance_log.reload
      expect(maintenance_log.status).to eq('cancelled')
    end

    it 'forbids update by other users' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      put :update, params: {
        id: maintenance_log.id,
        maintenance_log: { status: 'in_progress' }
      }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns errors for invalid update data' do
      put :update, params: {
        id: maintenance_log.id,
        maintenance_log: { cost: -50 }
      }
      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Update failed')
    end

    it 'returns not found for non-existent maintenance log' do
      put :update, params: {
        id: 99999,
        maintenance_log: { status: 'resolved' }
      }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    let!(:maintenance_log) do
      unit.maintenance_logs.create(
        title: 'Test maintenance',
        description: 'Test description',
        cost: 100.00,
        status: 'pending'
      )
    end

    it 'deletes maintenance log as owner' do
      expect {
        delete :destroy, params: { id: maintenance_log.id }
      }.to change(MaintenanceLog, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it 'deletes maintenance log as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      expect {
        delete :destroy, params: { id: maintenance_log.id }
      }.to change(MaintenanceLog, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it 'forbids delete by other users' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      delete :destroy, params: { id: maintenance_log.id }
      expect(response).to have_http_status(:forbidden)
    end
  end
end
require 'rails_helper'

RSpec.describe Api::V1::MaintenanceController, type: :controller do
  let!(:user) { User.create(email: 'user@example.com', password: 'password123') }
  let!(:admin) { User.create(email: 'admin@example.com', password: 'password123', role: 'admin') }
  let(:user_token) { user.generate_jwt }
  let(:admin_token) { admin.generate_jwt }
  let!(:property) { Property.create(user: user, name: 'Test Property', address: '123 St', property_type: 'apartment', status: 'occupied', property_status: 'pending', total_units: 5) }
  let!(:unit) { property.units.create(unit_number: '101', rent_amount: 1000, deposit_amount: 2000, occupancy_status: 'occupied') }

  before do
    request.headers['Authorization'] = "Bearer #{user_token}"
  end

  describe 'GET #dashboard' do
    let!(:pending_log) { unit.maintenance_logs.create(title: 'Fix leak', description: 'Desc', cost: 100, status: 'pending') }
    let!(:resolved_log) { unit.maintenance_logs.create(title: 'Paint wall', description: 'Desc', cost: 200, status: 'resolved') }

    it 'returns maintenance dashboard data for owner' do
      get :dashboard
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['total_properties']).to eq(1)
      expect(json['data']['total_maintenance_logs']).to eq(2)
      expect(json['data']['pending_requests']).to eq(1)
      expect(json['data']['resolved_requests']).to eq(1)
    end

    it 'returns maintenance dashboard data for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      # Create another property for admin view
      other_property = Property.create(user: User.create(email: 'other@example.com', password: 'password123'), name: 'Other Property', address: '456 St', property_type: 'apartment', status: 'vacant', property_status: 'pending', total_units: 3)
      other_property.units.create(unit_number: '201', rent_amount: 800, deposit_amount: 1600, occupancy_status: 'occupied')

      get :dashboard
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['total_properties']).to eq(2) # Admin sees all properties
    end

    it 'returns recent logs in dashboard' do
      get :dashboard
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['recent_logs']).to be_an(Array)
      expect(json['data']['recent_logs'].length).to be <= 10
    end
  end

  describe 'GET #index (property maintenance logs)' do
    let!(:pending_log) { unit.maintenance_logs.create(title: 'Fix leak', description: 'Desc', cost: 100, status: 'pending') }
    let!(:resolved_log) { unit.maintenance_logs.create(title: 'Paint wall', description: 'Desc', cost: 200, status: 'resolved') }

    it 'returns maintenance logs for property as owner' do
      get :index, params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(2)
      expect(json['meta']['total_count']).to eq(2)
      expect(json['meta']['pending_count']).to eq(1)
      expect(json['meta']['resolved_count']).to eq(1)
    end

    it 'filters by status' do
      get :index, params: { property_id: property.id, status: 'pending' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(1)
      expect(json['data'].first['status']).to eq('pending')
    end

    it 'returns error for invalid status filter' do
      get :index, params: { property_id: property.id, status: 'invalid' }
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns maintenance logs for property as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :index, params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access for other users property' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      get :index, params: { property_id: property.id }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for non-existent property' do
      get :index, params: { property_id: 99999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #show' do
    let!(:maintenance_log) { unit.maintenance_logs.create(title: 'Fix leak', description: 'Kitchen sink leaking', cost: 150.50, status: 'pending') }

    it 'returns maintenance log for owner' do
      get :show, params: { id: maintenance_log.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['title']).to eq('Fix leak')
      expect(json['data']['cost']).to eq('150.5')
      expect(json['data']['unit']['unit_number']).to eq('101')
      expect(json['data']['unit']['property']['name']).to eq('Test Property')
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
      expect {
        post :create, params: {
          property_id: property.id,
          unit_id: unit.id,
          maintenance_log: {
            title: 'Fix electrical outlet',
            description: 'Outlet in bedroom not working',
            cost: 75.00
          }
        }
      }.to change(MaintenanceLog, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['data']['title']).to eq('Fix electrical outlet')
      expect(json['data']['status']).to eq('pending') # Always starts as pending
      expect(json['data']['cost']).to eq('75.0')
    end

    it 'creates a maintenance log as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      post :create, params: {
        property_id: property.id,
        unit_id: unit.id,
        maintenance_log: {
          title: 'Replace filter',
          description: 'HVAC filter needs replacement',
          cost: 50.00
        }
      }
      expect(response).to have_http_status(:created)
    end

    it 'returns errors for invalid data' do
      post :create, params: {
        property_id: property.id,
        unit_id: unit.id,
        maintenance_log: {
          title: '',
          description: 'Test',
          cost: -100
        }
      }
      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Failed to create maintenance request')
    end

    it 'forbids creation for other users property' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      post :create, params: {
        property_id: property.id,
        unit_id: unit.id,
        maintenance_log: {
          title: 'Test',
          description: 'Test',
          cost: 100
        }
      }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for non-existent unit' do
      post :create, params: {
        property_id: property.id,
        unit_id: 99999,
        maintenance_log: {
          title: 'Test',
          description: 'Test',
          cost: 100
        }
      }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PUT #update' do
    let!(:maintenance_log) { unit.maintenance_logs.create(title: 'Fix leak', description: 'Desc', cost: 100, status: 'pending') }

    it 'updates maintenance log as owner' do
      put :update, params: {
        id: maintenance_log.id,
        maintenance_log: {
          status: 'in_progress',
          cost: 150.00
        }
      }
      expect(response).to have_http_status(:ok)
      maintenance_log.reload
      expect(maintenance_log.status).to eq('in_progress')
      expect(maintenance_log.cost).to eq(150.00)
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
    end
  end

  describe 'PATCH #resolve' do
    let!(:maintenance_log) { unit.maintenance_logs.create(title: 'Fix leak', description: 'Desc', cost: 100, status: 'in_progress') }

    it 'marks maintenance log as resolved' do
      patch :resolve, params: { id: maintenance_log.id }
      expect(response).to have_http_status(:ok)
      maintenance_log.reload
      expect(maintenance_log.status).to eq('resolved')
      expect(maintenance_log.resolved_at).to be_within(1.second).of(Time.current)
    end

    it 'returns error if resolve fails' do
      allow_any_instance_of(MaintenanceLog).to receive(:update).and_return(false)
      patch :resolve, params: { id: maintenance_log.id }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'forbids resolve by other users' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      patch :resolve, params: { id: maintenance_log.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE #destroy' do
    let!(:maintenance_log) { unit.maintenance_logs.create(title: 'Test', description: 'Desc', cost: 100, status: 'pending') }

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
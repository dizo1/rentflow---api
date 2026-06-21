require 'rails_helper'

RSpec.describe Api::V1::Admin::AdminsController, type: :controller do
  let!(:user) { User.create(email: 'user@example.com', password: 'password123') }
  let!(:admin) { User.create(email: 'admin@example.com', password: 'password123', role: 'admin') }
  let(:user_token) { user.generate_jwt }
  let(:admin_token) { admin.generate_jwt }

  before do
    @property = Property.create(user: user, name: 'Test Property', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 5)
    @unit = Unit.create(property: @property, unit_number: '101', rent_amount: 1000, deposit_amount: 1000, occupancy_status: 'vacant')
  end

  describe 'GET #dashboard' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      get :dashboard
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns dashboard data for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :dashboard
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']).to have_key('totals')
      expect(json_response['data']).to have_key('financials')
      expect(json_response['data']).to have_key('maintenance')
      expect(json_response['data']).to have_key('subscriptions')
      expect(json_response['data']).to have_key('recent_activity')
    end
  end

  describe 'GET #index' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      get :index
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns paginated users for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :index
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['data']).to be_an(Array)
      expect(json_response['data']['data'].length).to eq(2)
      expect(json_response['data']).to have_key('meta')
    end
  end

  describe 'GET #show' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      get :show, params: { id: user.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns user details for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :show, params: { id: user.id }
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['id']).to eq(user.id)
      expect(json_response['data']['email']).to eq(user.email)
    end
  end

  describe 'PATCH #update' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      patch :update, params: { id: user.id, user: { name: 'New Name' } }
      expect(response).to have_http_status(:forbidden)
    end

    it 'updates user for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      patch :update, params: { id: user.id, user: { name: 'New Name' } }
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['name']).to eq('New Name')
    end
  end

  describe 'PATCH #promote' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      patch :promote, params: { id: user.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'promotes user to admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      patch :promote, params: { id: user.id }
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['role']).to eq('admin')
    end
  end

  describe 'PATCH #demote' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      patch :demote, params: { id: user.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'demotes admin to user' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      patch :demote, params: { id: admin.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'demotes other admin to user' do
      other_admin = User.create(email: 'other_admin@example.com', password: 'password123', role: 'admin')
      request.headers['Authorization'] = "Bearer #{admin_token}"
      patch :demote, params: { id: other_admin.id }
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['role']).to eq('user')
    end
  end

  describe 'PATCH #suspend' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      patch :suspend, params: { id: user.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'suspends user' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      patch :suspend, params: { id: user.id }
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['active']).to be false
    end
  end

  describe 'PATCH #activate' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      patch :activate, params: { id: user.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'activates user' do
      user.update(active: false)
      request.headers['Authorization'] = "Bearer #{admin_token}"
      patch :activate, params: { id: user.id }
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['active']).to be true
    end
  end

  describe 'GET #properties' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      get :properties
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns paginated properties for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :properties
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['data']).to be_an(Array)
      expect(json_response['data']).to have_key('meta')
    end
  end

  describe 'GET #units' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      get :units
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns paginated units for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :units
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['data']).to be_an(Array)
      expect(json_response['data']).to have_key('meta')
    end
  end

  describe 'GET #tenants' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      get :tenants
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns paginated tenants for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :tenants
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['data']).to be_an(Array)
      expect(json_response['data']).to have_key('meta')
    end
  end

  describe 'GET #rent_records' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      get :rent_records
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns paginated rent records for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :rent_records
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['data']).to be_an(Array)
      expect(json_response['data']).to have_key('meta')
    end
  end

  describe 'GET #maintenance_logs' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      get :maintenance_logs
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns paginated maintenance logs for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :maintenance_logs
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['data']).to be_an(Array)
      expect(json_response['data']).to have_key('meta')
    end
  end

  describe 'GET #payments' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      get :payments
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns paginated payments for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :payments
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['data']).to be_an(Array)
      expect(json_response['data']).to have_key('meta')
    end
  end

  describe 'GET #subscriptions' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      get :subscriptions
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns paginated subscriptions for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :subscriptions
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['data']).to be_an(Array)
      expect(json_response['data']).to have_key('meta')
    end
  end

  describe 'GET #audit_logs' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      get :audit_logs
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns paginated audit logs for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :audit_logs
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['data']).to be_an(Array)
      expect(json_response['data']).to have_key('meta')
    end
  end
end

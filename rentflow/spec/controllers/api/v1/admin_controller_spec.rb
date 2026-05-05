require 'rails_helper'

RSpec.describe Api::V1::AdminController, type: :controller do
  let!(:user) { User.create(email: 'user@example.com', password: 'password123') }
  let!(:admin) { User.create(email: 'admin@example.com', password: 'password123', role: 'admin') }
  let(:user_token) { user.generate_jwt }
  let(:admin_token) { admin.generate_jwt }

  before do
    # Create some test data
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
      expect(json_response['data']).to have_key('stats')
      expect(json_response['data']).to have_key('recent_activity')
      expect(json_response['data']['stats']).to have_key('total_users')
      expect(json_response['data']['stats']).to have_key('total_properties')
      expect(json_response['data']['stats']).to have_key('total_units')
    end
  end

  describe 'GET #users' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      get :users
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns all users for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :users
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']).to be_an(Array)
      expect(json_response['data'].length).to eq(2) # user and admin
    end
  end

  describe 'GET #all_properties' do
    it 'requires admin access' do
      request.headers['Authorization'] = "Bearer #{user_token}"
      get :all_properties
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns all properties for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :all_properties
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']).to be_an(Array)
      expect(json_response['data'].length).to eq(1) # one test property
      expect(json_response['data'].first).to have_key('user')
    end
  end
end
require 'rails_helper'

RSpec.describe Api::V1::DashboardController, type: :controller do
  let!(:user) { User.create(email: 'user@example.com', password: 'password123', name: 'Test User') }
  let!(:admin) { User.create(email: 'admin@example.com', password: 'password123', role: 'admin') }
  let(:user_token) { user.generate_jwt }
  let(:admin_token) { admin.generate_jwt }

  before do
    request.headers['Authorization'] = "Bearer #{user_token}"
  end

  describe 'GET #show' do
    it 'returns dashboard data for logged-in user' do
      property1 = Property.create!(user: user, name: 'Property 1', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 5)
      property2 = Property.create!(user: user, name: 'Property 2', address: '456 Ave', property_type: 'house', status: 'occupied', total_units: 3)

      property1.units.create!(unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied')
      property1.units.create!(unit_number: '102', rent_amount: 1300, deposit_amount: 2600, occupancy_status: 'vacant')
      property2.units.create!(unit_number: '201', rent_amount: 1800, deposit_amount: 3600, occupancy_status: 'occupied')

      get :show

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['user']['email']).to eq('user@example.com')
      expect(json['data']['properties']['total']).to eq(2)
      expect(json['data']['units']['total']).to eq(3)
      expect(json['data']['units']['occupied']).to eq(2)
      expect(json['data']['units']['vacant']).to eq(1)
      expect(json['data']['revenue']['monthly_potential']).to eq(4300.0)
      expect(json['data']['revenue']['total_deposits']).to eq(8600.0)
    end

    it 'returns zero values when user has no properties' do
      get :show

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['properties']['total']).to eq(0)
      expect(json['data']['units']['total']).to eq(0)
      expect(json['data']['units']['occupied']).to eq(0)
      expect(json['data']['units']['vacant']).to eq(0)
      expect(json['data']['revenue']['monthly_potential']).to eq(0.0)
      expect(json['data']['revenue']['total_deposits']).to eq(0.0)
    end

    it 'only returns properties belonging to current user' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      Property.create(user: user, name: 'My Property', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 2)
      Property.create(user: other_user, name: 'Other Property', address: '456 Ave', property_type: 'house', status: 'occupied', total_units: 4)

      get :show

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['properties']['total']).to eq(1)
      expect(json['data']['properties']['data'].first['name']).to eq('My Property')
    end

    it 'only returns units belonging to current user' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      my_property = Property.create(user: user, name: 'My Property', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 5)
      other_property = Property.create(user: other_user, name: 'Other Property', address: '456 Ave', property_type: 'house', status: 'occupied', total_units: 3)

      my_property.units.create(unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied')
      other_property.units.create(unit_number: '201', rent_amount: 2000, deposit_amount: 4000, occupancy_status: 'occupied')

      get :show

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['units']['total']).to eq(1)
      expect(json['data']['units']['data'].first['unit_number']).to eq('101')
    end

    it 'returns unauthorized without token' do
      request.headers['Authorization'] = nil
      get :show
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'property dashboard hook' do
    it 'returns property-level dashboard data' do
      property = Property.create!(user: user, name: 'Test Property', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 5)
      property.units.create!(unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied')
      property.units.create!(unit_number: '102', rent_amount: 1300, deposit_amount: 2600, occupancy_status: 'vacant')

      data = property.dashboard_data

      expect(data[:id]).to eq(property.id)
      expect(data[:name]).to eq('Test Property')
      expect(data[:property_type]).to eq('apartment')
      expect(data[:status]).to eq('vacant')
      expect(data[:total_units]).to eq(5)
      expect(data[:units_count]).to eq(2)
      expect(data[:occupied_units]).to eq(1)
      expect(data[:vacant_units]).to eq(1)
      expect(data[:occupancy_rate]).to eq(20.0)
      expect(data[:monthly_revenue]).to eq(2500.0)
      expect(data[:total_deposits]).to eq(5000.0)
    end

    it 'calculates occupancy_rate as 0.0 when total_units is 0' do
      property = Property.create!(user: user, name: 'Empty Property', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 0)
      data = property.dashboard_data
      expect(data[:occupancy_rate]).to eq(0.0)
    end
  end
end

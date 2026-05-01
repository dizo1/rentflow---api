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

      unit1 = property1.units.create!(unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied')
      unit2 = property1.units.create!(unit_number: '102', rent_amount: 1300, deposit_amount: 2600, occupancy_status: 'vacant')
      unit3 = property2.units.create!(unit_number: '201', rent_amount: 1800, deposit_amount: 3600, occupancy_status: 'occupied')

      # Create tenants for the units
      tenant1 = unit1.create_tenant!(full_name: 'John Doe', phone: '1234567890', email: 'john@example.com', 
                                   move_in_date: Date.current, lease_start: Date.current, lease_end: 1.year.from_now,
                                   status: 'active')
      tenant2 = unit3.create_tenant!(full_name: 'Jane Smith', phone: '0987654321', email: 'jane@example.com',
                                   move_in_date: Date.current, lease_start: Date.current, lease_end: 1.year.from_now,
                                   status: 'active')

      # Create some rent records for current month
      current_month = Date.current.month
      current_year = Date.current.year
      unit1.rent_records.create!(
        month: current_month,
        year: current_year,
        amount_due: 1200,
        amount_paid: 1200,
        balance: 0,
        status: 'paid',
        due_date: Date.current
      )
      unit2.rent_records.create!(
        month: current_month,
        year: current_year,
        amount_due: 1300,
        amount_paid: 0,
        balance: 1300,
        status: 'overdue',
        due_date: Date.current
      )
      unit3.rent_records.create!(
        month: current_month,
        year: current_year,
        amount_due: 1800,
        amount_paid: 1800,
        balance: 0,
        status: 'paid',
        due_date: Date.current
      )

      # Create maintenance logs
      unit1.maintenance_logs.create!(
        title: 'Fix leaky faucet',
        description: 'Fix leaky faucet in kitchen',
        cost: 150,
        status: 'resolved',
        priority: 'medium',
        reported_date: Date.current
      )
      unit1.maintenance_logs.create!(
        title: 'Repair broken window',
        description: 'Replace broken window in bedroom',
        cost: 300,
        status: 'pending',
        priority: 'high',
        reported_date: Date.current
      )

      get :show

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['properties']).to eq(2)
      expect(json['data']['units']).to eq(3)
      expect(json['data']['tenants']).to eq(2)
      expect(json['data']['occupancy_rate']).to eq(66.67) # 2 out of 3 units occupied
      expect(json['data']['financials']['monthly_income']).to eq(3000) # 1200 + 1800
      expect(json['data']['financials']['overdue_rent']).to eq(1) # 1 overdue record
      expect(json['data']['financials']['collected_rent']).to eq(3000) # 1200 + 1800
      expect(json['data']['financials']['maintenance_cost']).to eq(150) # Only resolved maintenance
      expect(json['data']['financials']['net_income']).to eq(2850) # 3000 - 150
      expect(json['data']['maintenance']['pending']).to eq(1)
      expect(json['data']['maintenance']['resolved']).to eq(1)
    end

    it 'returns zero values when user has no properties' do
      get :show

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['properties']).to eq(0)
      expect(json['data']['units']).to eq(0)
      expect(json['data']['tenants']).to eq(0)
      expect(json['data']['occupancy_rate']).to eq(0.0)
      expect(json['data']['financials']['monthly_income']).to eq(0.0) # This is a float, not integer
      expect(json['data']['financials']['overdue_rent']).to eq(0)
      expect(json['data']['financials']['collected_rent']).to eq(0.0) # This is a float, not integer
      expect(json['data']['financials']['maintenance_cost']).to eq(0.0) # This is a float, not integer
      expect(json['data']['financials']['net_income']).to eq(0.0) # This is a float, not integer
      expect(json['data']['maintenance']['pending']).to eq(0)
      expect(json['data']['maintenance']['resolved']).to eq(0)
    end

    it 'only returns properties belonging to current user' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      Property.create(user: user, name: 'My Property', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 2)
      Property.create(user: other_user, name: 'Other Property', address: '456 Ave', property_type: 'house', status: 'occupied', total_units: 4)

      get :show

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['properties']).to eq(1)
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
      expect(json['success']).to be true
      expect(json['data']['units']).to eq(1)
    end

    it 'returns unauthorized without token' do
      request.headers['Authorization'] = nil
      get :show
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
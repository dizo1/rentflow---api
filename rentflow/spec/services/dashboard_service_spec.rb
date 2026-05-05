require 'rails_helper'

RSpec.describe DashboardService, type: :service do
  let(:user) { User.create(email: 'user@example.com', password: 'password123', name: 'Test User') }
  let(:service) { DashboardService.new(user) }

  describe '#call' do
    context 'when user has no properties' do
      it 'returns zero values for all metrics' do
        result = service.call
        
        expect(result[:properties]).to eq(0)
        expect(result[:units]).to eq(0)
        expect(result[:tenants]).to eq(0)
        expect(result[:occupancy_rate]).to eq(0.0)
        expect(result[:financials][:monthly_income]).to eq(0)
        expect(result[:financials][:overdue_rent]).to eq(0)
        expect(result[:financials][:collected_rent]).to eq(0)
        expect(result[:financials][:maintenance_cost]).to eq(0)
        expect(result[:financials][:net_income]).to eq(0)
        expect(result[:maintenance][:pending]).to eq(0)
        expect(result[:maintenance][:resolved]).to eq(0)
      end
    end

    context 'when user has properties with data' do
      before do
        # Create properties
        @property1 = Property.create!(user: user, name: 'Property 1', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 5)
        @property2 = Property.create!(user: user, name: 'Property 2', address: '456 Ave', property_type: 'house', status: 'occupied', total_units: 3)

        # Create units
        @unit1 = @property1.units.create!(unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied')
        @unit2 = @property1.units.create!(unit_number: '102', rent_amount: 1300, deposit_amount: 2600, occupancy_status: 'vacant')
        @unit3 = @property2.units.create!(unit_number: '201', rent_amount: 1800, deposit_amount: 3600, occupancy_status: 'occupied')

        # Create tenants
        @tenant1 = @unit1.create_tenant!(full_name: 'John Doe', phone: '1234567890', email: 'john@example.com', 
                                       move_in_date: Date.current, lease_start: Date.current, lease_end: 1.year.from_now,
                                       status: 'active')
        @tenant2 = @unit3.create_tenant!(full_name: 'Jane Smith', phone: '0987654321', email: 'jane@example.com',
                                       move_in_date: Date.current, lease_start: Date.current, lease_end: 1.year.from_now,
                                       status: 'active')

        # Create rent records for current month
        current_month = Date.current.month
        current_year = Date.current.year
        @unit1.rent_records.create!(
          month: current_month,
          year: current_year,
          amount_due: 1200,
          amount_paid: 1200,
          balance: 0,
          status: 'paid',
          due_date: Date.current
        )
        @unit2.rent_records.create!(
          month: current_month,
          year: current_year,
          amount_due: 1300,
          amount_paid: 0,
          balance: 1300,
          status: 'overdue',
          due_date: Date.current
        )
        @unit3.rent_records.create!(
          month: current_month,
          year: current_year,
          amount_due: 1800,
          amount_paid: 1800,
          balance: 0,
          status: 'paid',
          due_date: Date.current
        )

        # Create maintenance logs
        @unit1.maintenance_logs.create!(
          title: 'Fix leaky faucet',
          description: 'Fix leaky faucet in kitchen',
          cost: 150,
          status: 'resolved',
          priority: 'medium',
          reported_date: Date.current
        )
        @unit1.maintenance_logs.create!(
          title: 'Repair broken window',
          description: 'Replace broken window in bedroom',
          cost: 300,
          status: 'pending',
          priority: 'high',
          reported_date: Date.current
        )
      end

      it 'returns correct dashboard metrics' do
        result = service.call
        
        # Basic counts
        expect(result[:properties]).to eq(2)
        expect(result[:units]).to eq(3)
        expect(result[:tenants]).to eq(2)
        
        # Occupancy rate (2 out of 3 units occupied = 66.67%)
        expect(result[:occupancy_rate]).to eq(66.67)
        
        # Financials
        expect(result[:financials][:monthly_income]).to eq(3000)  # 1200 + 1800
        expect(result[:financials][:overdue_rent]).to eq(1)       # 1 overdue record
        expect(result[:financials][:collected_rent]).to eq(3000)  # 1200 + 1800
        expect(result[:financials][:maintenance_cost]).to eq(150) # Only resolved maintenance
        expect(result[:financials][:net_income]).to eq(2850)      # 3000 - 150
        
        # Maintenance
        expect(result[:maintenance][:pending]).to eq(1)           # 1 pending maintenance
        expect(result[:maintenance][:resolved]).to eq(1)          # 1 resolved maintenance
      end
    end

    context 'data isolation' do
      it 'only returns data belonging to the current user' do
        # Create properties for the current user (the one the service is initialized with)
        property1 = Property.create!(user: user, name: 'Property 1', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 5)
        property2 = Property.create!(user: user, name: 'Property 2', address: '456 Ave', property_type: 'house', status: 'occupied', total_units: 3)
        
        # Create units for current user
        property1.units.create!(unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied')
        property1.units.create!(unit_number: '102', rent_amount: 1300, deposit_amount: 2600, occupancy_status: 'vacant')
        property2.units.create!(unit_number: '201', rent_amount: 1800, deposit_amount: 3600, occupancy_status: 'occupied')

        # Create another user with their own properties
        other_user = User.create(email: 'other@example.com', password: 'password123')
        other_property = Property.create!(user: other_user, name: 'Other Property', address: '789 Oak', 
                                        property_type: 'apartment', status: 'occupied', total_units: 4)
        other_unit = other_property.units.create!(unit_number: '301', rent_amount: 2000, deposit_amount: 4000, 
                                                occupancy_status: 'occupied')
        other_unit.maintenance_logs.create!(
          title: 'Other maintenance',
          description: 'Other user maintenance',
          cost: 500,
          status: 'resolved',
          priority: 'medium',
          reported_date: Date.current
        )

        result = service.call
        
        # Should only see current user's data
        expect(result[:properties]).to eq(2)  # Only the two properties we created for the test user
        expect(result[:units]).to eq(3)       # Only the three units we created for the test user
        expect(result[:financials][:maintenance_cost]).to eq(0)  # No maintenance logs for current user's units
      end
    end
  end
end
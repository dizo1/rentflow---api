class Api::V1::DashboardController < Api::V1::BaseController
  before_action :authenticate_user

  # GET /api/v1/dashboard
  def show
    properties = Property.where(user: current_user)
    property_ids = properties.pluck(:id)
    units = Unit.where(property_id: property_ids)
    
    # Calculate occupancy rate
    total_units = units.count
    occupied_units = units.where(occupancy_status: 'occupied').count
    occupancy_rate = total_units > 0 ? (occupied_units.to_f / total_units * 100).round(2) : 0.0
    
    # Calculate overdue rent
    overdue_rent = RentRecord.joins(unit: :property)
                            .where(properties: { user_id: current_user.id })
                            .where(status: 'overdue')
                            .sum(:balance).to_f
    
    # Calculate maintenance costs (total cost of resolved maintenance logs)
    maintenance_costs = MaintenanceLog.joins(unit: :property)
                                     .where(properties: { user_id: current_user.id })
                                     .where(status: 'resolved')
                                     .sum(:cost).to_f
    
    # Calculate pending repairs (pending + in_progress maintenance logs)
    pending_repairs = MaintenanceLog.joins(unit: :property)
                                   .where(properties: { user_id: current_user.id })
                                   .where(status: ['pending', 'in_progress'])
                                   .count

    render_success({
      user: current_user.as_json(only: [:id, :name, :email, :role]),
      # Top-level metrics as requested
      total_properties: properties.count,
      total_units: total_units,
      occupancy_rate: occupancy_rate,
      monthly_rent_income: units.sum(:rent_amount).to_f,
      overdue_rent: overdue_rent,
      maintenance_costs: maintenance_costs,
      pending_repairs: pending_repairs,
      # Preserving existing structure for backward compatibility
      properties: {
        total: properties.count,
        data: properties.as_json(only: [:id, :name, :address, :property_type, :status, :total_units])
      },
      property_dashboards: properties.map { |p| p.dashboard_data },
      units: {
        total: total_units,
        occupied: occupied_units,
        vacant: units.where(occupancy_status: 'vacant').count,
        occupancy_rate: occupancy_rate,
        data: units.as_json(only: [:id, :property_id, :unit_number, :rent_amount, :deposit_amount, :occupancy_status, :tenant_name, :tenant_phone])
      },
      revenue: {
        monthly_potential: units.sum(:rent_amount).to_f,
        total_deposits: units.sum(:deposit_amount).to_f
      },
      financial: {
        overdue_rent: overdue_rent
      },
      maintenance: {
        total_costs: maintenance_costs,
        pending_repairs: pending_repairs
      }
    }, 'Dashboard data retrieved successfully')
  end
end

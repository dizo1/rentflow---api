class Api::V1::DashboardController < Api::V1::BaseController
  before_action :authenticate_user

  # GET /api/v1/dashboard
  def show
    properties = Property.where(user: current_user)
    property_ids = properties.pluck(:id)
    units = Unit.where(property_id: property_ids)

    render_success({
      user: current_user.as_json(only: [:id, :name, :email, :role]),
      properties: {
        total: properties.count,
        owned: properties.count,
        data: properties.as_json(only: [:id, :name, :address, :property_type, :status, :total_units])
      },
      property_dashboards: properties.map { |p| p.dashboard_data },
      units: {
        total: units.count,
        occupied: units.where(occupancy_status: 'occupied').count,
        vacant: units.where(occupancy_status: 'vacant').count,
        data: units.as_json(only: [:id, :property_id, :unit_number, :rent_amount, :deposit_amount, :occupancy_status, :tenant_name, :tenant_phone])
      },
      revenue: {
        monthly_potential: units.sum(:rent_amount).to_f,
        total_deposits: units.sum(:deposit_amount).to_f
      }
    }, 'Dashboard data retrieved successfully')
  end
end

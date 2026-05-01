class Api::V1::AdminController < Api::V1::BaseController
  before_action :authenticate_user
  before_action :require_admin

  # GET /api/v1/admin/dashboard
  def dashboard
    # System-wide statistics for admin dashboard
    total_users = User.count
    total_properties = Property.count
    total_units = Unit.count
    occupied_units = Unit.where(occupancy_status: 'occupied').count
    vacancy_rate = total_units > 0 ? ((total_units - occupied_units).to_f / total_units * 100).round(2) : 0.0
    
    # Financial metrics
    total_rent_due = RentRecord.where.not(status: 'paid').sum(:balance).to_f
    total_maintenance_cost = MaintenanceLog.where(status: 'resolved').sum(:cost).to_f
    pending_maintenance = MaintenanceLog.where(status: ['pending', 'in_progress']).count
    
    # Recent activity
    recent_users = User.order(created_at: :desc).limit(5).as_json(only: [:id, :name, :email, :role, :created_at])
    recent_properties = Property.order(created_at: :desc).limit(5).as_json(only: [:id, :name, :address, :created_at])

    render_success({
      stats: {
        total_users: total_users,
        total_properties: total_properties,
        total_units: total_units,
        occupied_units: occupied_units,
        vacancy_rate: vacancy_rate,
        total_rent_due: total_rent_due,
        total_maintenance_cost: total_maintenance_cost,
        pending_maintenance: pending_maintenance
      },
      recent_activity: {
        users: recent_users,
        properties: recent_properties
      }
    }, 'Admin dashboard data retrieved successfully')
  end

  # GET /api/v1/admin/users
  def users
    users = User.all.as_json(only: [:id, :name, :email, :role, :created_at, :updated_at])
    render_success(users, 'All users retrieved successfully')
  end

  # GET /api/v1/admin/properties
  def all_properties
    properties = Property.includes(:user).all.as_json(include: { user: { only: [:id, :name, :email] } })
    render_success(properties, 'All properties retrieved successfully')
  end

  private

  def require_admin
    render_forbidden('Admin access required') unless admin_user?
  end
end
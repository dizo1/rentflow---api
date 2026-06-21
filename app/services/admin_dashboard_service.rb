class AdminDashboardService
  def call
    {
      totals: totals,
      financials: financials,
      maintenance: maintenance,
      subscriptions: subscription_breakdown,
      recent_activity: recent_activity
    }
  end

  private

  def totals
    {
      users: User.count,
      active_users: User.active.count,
      inactive_users: User.inactive.count,
      admins: User.where(role: "admin").count,
      properties: Property.count,
      units: Unit.count,
      occupied_units: Unit.where(occupancy_status: "occupied").count,
      vacant_units: Unit.where(occupancy_status: "vacant").count,
      tenants: Tenant.count,
      active_tenants: Tenant.where(status: "active").count
    }.tap do |data|
      total_units = data[:units]
      data[:occupancy_rate] = total_units.positive? ? ((data[:occupied_units].to_f / total_units) * 100).round(2) : 0.0
    end
  end

  def financials
    {
      total_rent_due: RentRecord.where.not(status: %w[paid waived]).sum(:balance).to_f,
      monthly_income: RentRecord.where(month: Date.current.month, year: Date.current.year, status: "paid").sum(:amount_paid).to_f,
      collected_rent: RentRecord.where(status: "paid").sum(:amount_paid).to_f,
      maintenance_cost: MaintenanceLog.where(status: "resolved").sum(:cost).to_f,
      net_income: RentRecord.where(status: "paid").sum(:amount_paid).to_f - MaintenanceLog.where(status: "resolved").sum(:cost).to_f
    }
  end

  def maintenance
    {
      pending: MaintenanceLog.where(status: "pending").count,
      in_progress: MaintenanceLog.where(status: "in_progress").count,
      resolved: MaintenanceLog.where(status: "resolved").count,
      cancelled: MaintenanceLog.where(status: "cancelled").count
    }
  end

  def subscription_breakdown
    Subscription.group(:plan).count.merge(Subscription.group(:status).count.transform_keys { |key| "status_#{key}" })
  end

  def recent_activity
    {
      users: User.order(created_at: :desc).limit(5).as_json(only: [ :id, :name, :email, :role, :active, :created_at ]),
      properties: Property.order(created_at: :desc).limit(5).as_json(only: [ :id, :name, :address, :property_type, :status, :created_at ]),
      maintenance_logs: MaintenanceLog.order(created_at: :desc).limit(5).as_json(only: [ :id, :title, :status, :priority, :created_at ])
    }
  end
end

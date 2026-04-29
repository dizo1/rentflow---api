class DashboardService
  def initialize(user)
    @user = user
  end

  def call
    {
      properties: total_properties,
      units: total_units,
      tenants: total_tenants,
      occupancy_rate: occupancy_rate,
      financials: {
        monthly_income: total_monthly_income,
        overdue_rent: total_overdue_rent,
        collected_rent: total_collected_rent,
        maintenance_cost: total_maintenance_cost,
        net_income: net_income
      },
      maintenance: {
        pending: pending_maintenance_count,
        resolved: resolved_maintenance_count
      }
    }
  end

  private

  def total_properties
    @total_properties ||= Property.where(user: @user).count
  end

  def total_units
    @total_units ||= Unit.joins(:property).where(properties: { user: @user }).count
  end

  def total_tenants
    @total_tenants ||= Tenant.joins(unit: :property).where(properties: { user: @user }).count
  end

  def occupancy_rate
    @occupancy_rate ||= begin
      total = total_units
      return 0 if total.zero?
      occupied = Unit.joins(:property)
                    .where(properties: { user: @user }, occupancy_status: "occupied")
                    .count
      ((occupied.to_f / total) * 100).round(2)
    end
  end

   def total_monthly_income
     @total_monthly_income ||= begin
       current_month = Date.current.month
       current_year = Date.current.year
       RentRecord.joins(unit: :property)
                 .where(properties: { user: @user })
                 .where(month: current_month, year: current_year, status: "paid")
                 .sum(:amount_paid).to_f
     end
   end

  def total_overdue_rent
    @total_overdue_rent ||= RentRecord.joins(unit: :property)
                                     .where(properties: { user: @user })
                                     .where(status: "overdue")
                                     .count
  end

   def total_collected_rent
     @total_collected_rent ||= RentRecord.joins(unit: :property)
                                        .where(properties: { user: @user })
                                        .where(status: "paid")
                                        .sum(:amount_paid).to_f
   end

   def total_maintenance_cost
     @total_maintenance_cost ||= MaintenanceLog.joins(unit: :property)
                                              .where(properties: { user: @user })
                                              .where(status: "resolved")
                                              .sum(:cost).to_f
   end

  def net_income
    @net_income ||= total_collected_rent - total_maintenance_cost
  end

  def pending_maintenance_count
    @pending_maintenance_count ||= MaintenanceLog.joins(unit: :property)
                                                .where(properties: { user: @user })
                                                .where(status: [ "pending", "in_progress" ])
                                                .count
  end

  def resolved_maintenance_count
    @resolved_maintenance_count ||= MaintenanceLog.joins(unit: :property)
                                                 .where(properties: { user: @user })
                                                 .where(status: "resolved")
                                                 .count
  end
end

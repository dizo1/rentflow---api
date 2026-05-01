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
      },
      subscription: subscription_data,
      payments: recent_payments
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

  def subscription_data
    subscription = @user.subscription
    return nil unless subscription

    days_left = if subscription.trialing? && subscription.trial_ends_at
                  [(subscription.trial_ends_at.to_date - Date.current).to_i, 0].max
                else
                  # For active plans, perhaps show until ends_at or nil
                  subscription.ends_at ? [(subscription.ends_at.to_date - Date.current).to_i, 0].max : nil
                end

    plan_config = PlanConfig.get_plan_config(subscription.plan)

    {
      plan: subscription.plan,
      status: subscription.status,
      days_left: days_left,
      usage: {
        properties_used: total_properties,
        property_limit: plan_config[:property_limit],
        units_used: total_units,
        unit_limit: plan_config[:unit_limit],
        sms_used: subscription.sms_used,
        sms_limit: plan_config[:sms_limit]
      },
      features: plan_config[:features]
    }
  end

  def recent_payments
    @user.payments.where(status: :successful).order(paid_at: :desc).limit(5).map do |payment|
      {
        amount: payment.amount,
        plan: payment.plan,
        status: payment.status,
        paid_at: payment.paid_at
      }
    end
  end
end

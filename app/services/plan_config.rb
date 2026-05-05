class PlanConfig
  PLANS = {
    trial: {
      unit_limit: 3,
      property_limit: 1,
      sms_limit: 10,
      features: ['basic_dashboard', 'rent_tracking', 'maintenance'],
      analytics_enabled: false,
      exports_enabled: false,
      bulk_sms_enabled: false
    },
    basic: {
      unit_limit: 10,
      property_limit: 3,
      sms_limit: 50,
      features: ['basic_dashboard', 'rent_tracking', 'maintenance', 'reminders'],
      analytics_enabled: false,
      exports_enabled: false,
      bulk_sms_enabled: false
    },
    pro: {
      unit_limit: -1,
      property_limit: -1,
      sms_limit: 500,
      features: ['basic_dashboard', 'rent_tracking', 'maintenance', 'reminders', 'analytics', 'exports', 'bulk_sms'],
      analytics_enabled: true,
      exports_enabled: true,
      bulk_sms_enabled: true
    }
  }.freeze

  def self.for(plan)
    PLANS[plan.to_sym] || PLANS[:trial]
  end

  def self.unit_limit(plan)
    for(plan)[:unit_limit]
  end

  def self.property_limit(plan)
    for(plan)[:property_limit]
  end

  def self.sms_limit(plan)
    for(plan)[:sms_limit]
  end

  def self.analytics_enabled?(plan)
    for(plan)[:analytics_enabled]
  end

  def self.exports_enabled?(plan)
    for(plan)[:exports_enabled]
  end

  def self.bulk_sms_enabled?(plan)
    for(plan)[:bulk_sms_enabled]
  end
end
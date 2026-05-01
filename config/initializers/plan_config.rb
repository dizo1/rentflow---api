class PlanConfig
  PLANS = {
    trial: {
      property_limit: 1,
      unit_limit: 5,
      sms_limit: 20,
      features: {
        analytics: false,
        exports: false,
        bulk_sms: false
      }
    },
    basic: {
      property_limit: 5,
      unit_limit: 50,
      sms_limit: 200,
      features: {
        analytics: false,
        exports: false,
        bulk_sms: false
      }
    },
    pro: {
      property_limit: 20,
      unit_limit: 300,
      sms_limit: 1000,
      features: {
        analytics: true,
        exports: true,
        bulk_sms: true
      }
    }
  }.freeze

  def self.get_plan_config(plan)
    PLANS[plan.to_sym] || {}
  end

  def self.property_limit(plan)
    get_plan_config(plan)[:property_limit] || 0
  end

  def self.unit_limit(plan)
    get_plan_config(plan)[:unit_limit] || 0
  end

  def self.sms_limit(plan)
    get_plan_config(plan)[:sms_limit] || 0
  end

  def self.features(plan)
    get_plan_config(plan)[:features] || {}
  end

  def self.analytics_enabled?(plan)
    features(plan)[:analytics] || false
  end

  def self.exports_enabled?(plan)
    features(plan)[:exports] || false
  end

  def self.bulk_sms_enabled?(plan)
    features(plan)[:bulk_sms] || false
  end
end

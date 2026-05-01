class PlanAccessService
  def self.can_create_property?(user)
    return true if user.admin?
    subscription = user.subscription
    return false unless subscription
    subscription.check_and_expire!
    return false unless subscription.active? || subscription.trialing?
    properties_used = user.properties.count
    properties_used < PlanConfig.property_limit(subscription.plan)
  end

  def self.can_create_unit?(user)
    return true if user.admin?
    subscription = user.subscription
    return false unless subscription
    subscription.check_and_expire!
    return false unless subscription.active? || subscription.trialing?
    units_used = user.units.count
    units_used < PlanConfig.unit_limit(subscription.plan)
  end

  def self.can_send_sms?(user)
    return true if user.admin?
    subscription = user.subscription
    return false unless subscription
    subscription.check_and_expire!
    return false unless subscription.active? || subscription.trialing?
    subscription.sms_used < PlanConfig.sms_limit(subscription.plan)
  end

  def self.can_access_advanced_analytics?(user)
    return true if user.admin?
    subscription = user.subscription
    return false unless subscription
    subscription.check_and_expire!
    return false unless subscription.active? || subscription.trialing?
    PlanConfig.analytics_enabled?(subscription.plan)
  end

  def self.can_export_reports?(user)
    return true if user.admin?
    subscription = user.subscription
    return false unless subscription
    subscription.check_and_expire!
    return false unless subscription.active? || subscription.trialing?
    PlanConfig.exports_enabled?(subscription.plan)
  end

  def self.can_use_bulk_sms?(user)
    return true if user.admin?
    subscription = user.subscription
    return false unless subscription
    subscription.check_and_expire!
    return false unless subscription.active? || subscription.trialing?
    PlanConfig.bulk_sms_enabled?(subscription.plan)
  end
end

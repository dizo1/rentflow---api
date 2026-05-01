class SubscriptionService
  def upgrade_plan(user, plan)
    subscription = user.subscription
    return false unless subscription

    subscription.update!(
      plan: plan,
      status: :active,
      starts_at: Time.current,
      ends_at: 30.days.from_now
    )

    # Optional: Reset usage if needed, but for now keep existing usage
    true
  end
end

class Subscription < ApplicationRecord
  belongs_to :user

  enum :plan, { trial: 0, basic: 1, pro: 2 }
  enum :status, { trialing: 0, active: 1, expired: 2, cancelled: 3, suspended: 4 }

  validates :plan, presence: true
  validates :status, presence: true
  validates :sms_used, numericality: { greater_than_or_equal_to: 0 }

  def expired?
    return true if trialing? && trial_ends_at && trial_ends_at < Time.current
    return true if ends_at && ends_at < Time.current
    false
  end

  def check_and_expire!
    if expired? && status != 'expired'
      update(status: :expired)
    end
  end
end

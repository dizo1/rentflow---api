require 'jwt'

class User < ApplicationRecord
    has_secure_password
    has_many :properties, dependent: :destroy
    has_many :units, through: :properties
    has_one :subscription, dependent: :destroy

    validates :email, presence: true, uniqueness: true
    validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

    enum :role, { user: 'user', admin: 'admin' }, default: :user

    after_create :create_trial_subscription

    def generate_jwt
        JWT.encode({ user_id: id, exp: 24.hours.from_now.to_i }, Rails.application.secret_key_base)
    end

    def admin?
        role == 'admin'
    end

    private

    def create_trial_subscription
        Subscription.create!(
            user: self,
            plan: :trial,
            status: :trialing,
            trial_ends_at: 7.days.from_now,
            sms_used: 0
        )
    end
end

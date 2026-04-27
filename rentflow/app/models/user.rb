require 'jwt'

class User < ApplicationRecord
    has_secure_password
    has_many :properties, dependent: :destroy
    has_many :units, through: :properties

    validates :email, presence: true, uniqueness: true
    validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

    enum :role, { user: 'user', admin: 'admin' }, default: :user

    def generate_jwt
        JWT.encode({ user_id: id, exp: 24.hours.from_now.to_i }, Rails.application.secret_key_base)
    end

    def admin?
        role == 'admin'
    end
end

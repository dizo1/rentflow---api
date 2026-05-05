class Notification < ApplicationRecord
  belongs_to :user

  # Validations
  validates :title, presence: true
  validates :message, presence: true
  validates :notification_type, presence: true
  validates :read_status, inclusion: { in: [ true, false ] }

  # Scopes
  scope :unread, -> { where(read_status: false) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
end

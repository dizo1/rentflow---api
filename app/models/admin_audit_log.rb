class AdminAuditLog < ApplicationRecord
  belongs_to :admin, class_name: "User"

  validates :action, presence: true
  validates :target_type, presence: true
  validates :metadata, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_target, ->(target_type, target_id) { where(target_type: target_type, target_id: target_id) }
end

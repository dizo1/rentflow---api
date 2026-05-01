class Payment < ApplicationRecord
  belongs_to :user

  enum :plan, { basic: 0, pro: 1 }
  enum :status, { pending: 0, successful: 1, failed: 2 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :plan, presence: true
  validates :status, presence: true
  validates :reference, presence: true, uniqueness: true
end

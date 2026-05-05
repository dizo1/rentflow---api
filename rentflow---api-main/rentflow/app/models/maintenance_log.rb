class MaintenanceLog < ApplicationRecord
  belongs_to :unit

  enum :status, { pending: 'pending', in_progress: 'in_progress', resolved: 'resolved', cancelled: 'cancelled' }, validate: true

  validates :title, presence: true
  validates :description, presence: true
  validates :cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true

  before_save :set_resolved_at, if: :status_changed_to_resolved?

  scope :pending, -> { where(status: 'pending') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :resolved, -> { where(status: 'resolved') }
  scope :cancelled, -> { where(status: 'cancelled') }

  private

  def status_changed_to_resolved?
    status_changed? && status == 'resolved'
  end

  def set_resolved_at
    self.resolved_at ||= Time.current
  end
end
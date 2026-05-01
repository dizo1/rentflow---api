class MaintenanceLog < ApplicationRecord
  belongs_to :unit

  # Enums
  enum :status, {
    pending: 'pending',
    in_progress: 'in_progress',
    resolved: 'resolved',
    cancelled: 'cancelled'
  }, validate: true

  enum :priority, {
    low: 'low',
    medium: 'medium',
    high: 'high',
    urgent: 'urgent'
  }, validate: true

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true
  validates :cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validates :priority, presence: true
  validates :reported_date, presence: true
  validates :assigned_to, length: { maximum: 255 }, allow_blank: true
  validates :notes, length: { maximum: 2000 }, allow_blank: true

  # Callbacks
  before_validation :set_default_reported_date, on: :create
  before_validation :set_default_priority, on: :create
  before_save :set_resolved_at, if: :status_changed_to_resolved?
  before_save :clear_resolved_at, if: :status_changed_away_from_resolved?

  # Scopes
  scope :pending, -> { where(status: :pending) }
  scope :in_progress, -> { where(status: :in_progress) }
  scope :resolved, -> { where(status: :resolved) }
  scope :cancelled, -> { where(status: :cancelled) }
  scope :by_priority, ->(priority) { where(priority: priority) if priority.present? }
  scope :open, -> { where(status: ['pending', 'in_progress']) }
  scope :closed, -> { where(status: ['resolved', 'cancelled']) }

  # Instance methods

  # Mark as in progress
  def mark_in_progress!
    update!(status: 'in_progress')
  end

  # Mark as resolved (auto-sets resolved_at)
  def mark_resolved!
    update!(status: 'resolved')
  end

  # Mark as cancelled
  def cancel!
    update!(status: 'cancelled')
  end

  # Check if maintenance is completed (resolved or cancelled)
  def completed?
    %w[resolved cancelled].include?(status)
  end

  # Days taken to resolve (nil if not resolved)
  def days_to_resolve
    return nil unless resolved_at.present? && reported_date.present?
    (resolved_at.to_date - reported_date).to_i
  end

  # Dashboard hook - returns maintenance-related metrics for this log
  def summary
    {
      id: id,
      title: title,
      status: status,
      priority: priority,
      cost: cost.to_f,
      days_to_resolve: days_to_resolve,
      reported_date: reported_date,
      resolved_at: resolved_at
    }
  end

  private

  def set_default_reported_date
    self.reported_date ||= Date.current
  end

  def set_default_priority
    self.priority ||= 'medium'
  end

  def status_changed_to_resolved?
    status_changed? && status == 'resolved'
  end

  def status_changed_away_from_resolved?
    # Trigger when status changes from resolved to something else
    status_changed? && status_previously_was == 'resolved' && status != 'resolved'
  end

  def set_resolved_at
    self.resolved_at ||= Time.current
  end

  def clear_resolved_at
    self.resolved_at = nil
  end
end

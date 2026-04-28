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

  # Dashboard hook - returns maintenance-related metrics
  def self.dashboard_data(property_ids = nil)
    scope = self.all
    scope = scope.joins(unit: :property).where(properties: { id: property_ids }) if property_ids.present?

    {
      total_maintenance_logs: scope.count,
      pending_requests: scope.pending.count,
      in_progress_requests: scope.in_progress.count,
      resolved_requests: scope.resolved.count,
      cancelled_requests: scope.cancelled.count,
      recent_logs: scope
        .where(created_at: 30.days.ago..Time.current)
        .order(created_at: :desc)
        .limit(10)
        .map { |log|
          {
            id: log.id,
            title: log.title,
            description: log.description,
            cost: log.cost,
            status: log.status,
            resolved_at: log.resolved_at,
            created_at: log.created_at,
            updated_at: log.updated_at,
            unit: {
              id: log.unit.id,
              unit_number: log.unit.unit_number,
              property: {
                id: log.unit.property.id,
                name: log.unit.property.name
              }
            }
          }
        }
    }
  end

  private

  def status_changed_to_resolved?
    status_changed? && status == 'resolved'
  end

  def set_resolved_at
    self.resolved_at ||= Time.current
  end
end
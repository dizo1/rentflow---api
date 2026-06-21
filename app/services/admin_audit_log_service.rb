class AdminAuditLogService
  def self.record(admin:, action:, target_type:, target_id: nil, metadata: {}, ip_address: nil, user_agent: nil)
    AdminAuditLog.create!(
      admin: admin,
      action: action,
      target_type: target_type,
      target_id: target_id,
      ip_address: ip_address,
      user_agent: user_agent,
      metadata: metadata.compact
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    Rails.logger.warn("[AdminAuditLog] Failed to record audit log: #{e.message}")
  end
end

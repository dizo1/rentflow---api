class Api::V1::Admin::AdminsController < Api::V1::BaseController
  before_action :require_admin
  before_action :set_admin_user, only: [ :show, :update, :promote, :demote, :suspend, :activate ]
  after_action :audit_admin_request

  def dashboard
    render_success(AdminDashboardService.new.call, "Admin dashboard data retrieved successfully")
  end

  def index
    render_paginated_collection(User.includes(:subscription).order(created_at: :desc), "Users retrieved successfully")
  end

  def show
    render_success(user_json(@admin_user), "User retrieved successfully")
  end

  def update
    if @admin_user.update(user_params)
      set_audit_target(@admin_user)
      render_success(user_json(@admin_user), "User updated successfully")
    else
      render_error("Update failed", :unprocessable_content, @admin_user.errors.full_messages)
    end
  end

  def promote
    change_user_role("admin", "User promoted to admin")
  end

  def demote
    return render_error("Admins cannot demote themselves", :forbidden) if @admin_user.id == current_user.id

    change_user_role("user", "User demoted to standard user")
  end

  def suspend
    return render_error("Admins cannot suspend themselves", :forbidden) if @admin_user.id == current_user.id

    if @admin_user.update(active: false)
      set_audit_target(@admin_user)
      render_success(user_json(@admin_user), "User suspended successfully")
    else
      render_error("Suspend failed", :unprocessable_content, @admin_user.errors.full_messages)
    end
  end

  def activate
    if @admin_user.update(active: true)
      set_audit_target(@admin_user)
      render_success(user_json(@admin_user), "User activated successfully")
    else
      render_error("Activate failed", :unprocessable_content, @admin_user.errors.full_messages)
    end
  end

  def properties
    collection = Property.includes(:user).order(created_at: :desc)
    collection = apply_property_filters(collection)
    render_paginated_collection(collection, "Properties retrieved successfully")
  end

  def units
    collection = Unit.includes(property: :user).joins(:property).order(created_at: :desc)
    collection = apply_unit_filters(collection)
    render_paginated_collection(collection, "Units retrieved successfully")
  end

  def tenants
    collection = Tenant.includes(:unit).joins(unit: :property).order(created_at: :desc)
    collection = apply_tenant_filters(collection)
    render_paginated_collection(collection, "Tenants retrieved successfully")
  end

  def rent_records
    collection = RentRecord.includes(tenant: :unit, unit: :property).joins(unit: :property).order(created_at: :desc)
    collection = apply_rent_record_filters(collection)
    render_paginated_collection(collection, "Rent records retrieved successfully")
  end

  def maintenance_logs
    collection = MaintenanceLog.includes(unit: :property).joins(unit: :property).order(created_at: :desc)
    collection = apply_maintenance_filters(collection)
    render_paginated_collection(collection, "Maintenance logs retrieved successfully")
  end

  def payments
    collection = Payment.includes(:user).order(created_at: :desc)
    collection = collection.where(status: params[:status]) if params[:status].present?
    collection = collection.where(plan: params[:plan]) if params[:plan].present?
    render_paginated_collection(collection, "Payments retrieved successfully")
  end

  def subscriptions
    collection = Subscription.includes(:user).order(created_at: :desc)
    collection = collection.where(status: params[:status]) if params[:status].present?
    collection = collection.where(plan: params[:plan]) if params[:plan].present?
    render_paginated_collection(collection, "Subscriptions retrieved successfully")
  end

  def audit_logs
    collection = AdminAuditLog.includes(:admin).order(created_at: :desc)
    collection = collection.where(action: params[:audit_action]) if params[:audit_action].present?
    collection = collection.where(target_type: params[:target_type]) if params[:target_type].present?
    render_paginated_collection(collection, "Admin audit logs retrieved successfully")
  end

  private

  def require_admin
    render_forbidden("Admin access required") unless admin_user?
  end

  def set_admin_user
    @admin_user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found("User not found")
  end

  def change_user_role(role, message)
    if @admin_user.update(role: role)
      set_audit_target(@admin_user)
      render_success(user_json(@admin_user), message)
    else
      render_error("Role update failed", :unprocessable_content, @admin_user.errors.full_messages)
    end
  end

  def render_paginated_collection(collection, message)
    result = paginate(collection)
    render_success(
      {
        data: result[:data],
        meta: result[:meta]
      },
      message
    )
  end

  def user_json(user)
    user.as_json(only: [ :id, :name, :email, :role, :active, :created_at, :updated_at ], methods: [ :admin? ])
  end

  def user_params
    params.require(:user).permit(:name, :email, :role, :active)
  end

  def apply_property_filters(collection)
    collection = collection.where(status: params[:status]) if params[:status].present?
    collection = collection.where(property_type: params[:property_type]) if params[:property_type].present?
    collection = collection.where(property_status: params[:property_status]) if params[:property_status].present?

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      collection = collection.where("name ILIKE ? OR address ILIKE ?", search_term, search_term)
    end

    collection
  end

  def apply_unit_filters(collection)
    collection = collection.where(occupancy_status: params[:occupancy_status]) if params[:occupancy_status].present?
    collection = collection.where(properties: { status: params[:property_status] }) if params[:property_status].present?

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      collection = collection.where("unit_number ILIKE ?", search_term)
    end

    collection
  end

  def apply_tenant_filters(collection)
    collection = collection.where(status: params[:status]) if params[:status].present?

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      collection = collection.where("full_name ILIKE ? OR email ILIKE ? OR phone ILIKE ?", search_term, search_term, search_term)
    end

    collection
  end

  def apply_rent_record_filters(collection)
    collection = collection.where(status: params[:status]) if params[:status].present?
    collection = collection.where(month: params[:month].to_i) if params[:month].present?
    collection = collection.where(year: params[:year].to_i) if params[:year].present?
    collection
  end

  def apply_maintenance_filters(collection)
    collection = collection.where(status: params[:status]) if params[:status].present?
    collection = collection.where(priority: params[:priority]) if params[:priority].present?
    collection
  end

  def audit_admin_request
    AdminAuditLogService.record(
      admin: current_user,
      action: action_name,
      target_type: @audit_target_type || "AdminApi",
      target_id: @audit_target_id,
      metadata: audit_metadata.presence || { controller: params[:controller] },
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  rescue => e
    Rails.logger.error "[AdminAuditLog] Failed to record: #{e.message}"
  end

  def audit_metadata
    {
    controller: params[:controller],
    action: params[:action],
    route_params: audit_route_params
    }.compact
  end

  def audit_route_params
    params.to_unsafe_h.slice("id", "page", "per_page", "search", "status", "property_status", "property_type", "occupancy_status", "month", "year", "priority", "plan", "target_type")
  end

  def set_audit_target(target)
    @audit_target_type = target.class.name
    @audit_target_id = target.id
  end
end

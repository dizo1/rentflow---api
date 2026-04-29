class Api::V1::DashboardController < Api::V1::BaseController
  before_action :authenticate_user

  # GET /api/v1/dashboard
  def show
    dashboard_service = DashboardService.new(current_user)
    dashboard_data = dashboard_service.call

    render_success(dashboard_data, "Dashboard data retrieved successfully")
  end
end

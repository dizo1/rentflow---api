class Api::V1::PropertiesController < Api::V1::BaseController
  before_action :require_admin, only: [:index, :create]
  before_action :set_property, only: [:show, :update, :destroy, :generate_rent]
  before_action :authorize_property, only: [:show, :update, :destroy, :generate_rent]

  def index
    if admin_user?
      properties = Property.all
    else
      properties = Property.where(user_id: current_user.id)
    end
    render_success(properties.as_json(only: [:id, :name, :address, :property_type, :status, :total_units, :user_id]), 'Properties retrieved successfully')
  end

  def show
    render_success(@property.as_json(only: [:id, :name, :address, :property_type, :status, :total_units, :user_id]), 'Property retrieved successfully')
  end

  def create
    property = Property.new(property_params)
    if property.save
      render_success(property.as_json(only: [:id, :name, :address, :property_type, :status, :total_units, :user_id]), 'Property created successfully', :created)
    else
      render_error('Validation failed', :unprocessable_content, property.errors.full_messages)
    end
  end

  def update
    if @property.update(property_params)
      render_success(@property.as_json(only: [:id, :name, :address, :property_type, :status, :total_units, :user_id]), 'Property updated successfully')
    else
      render_error('Update failed', :unprocessable_content, @property.errors.full_messages)
    end
  end

  def destroy
    @property.destroy
    render_success(nil, 'Property deleted successfully', :no_content)
  end

  def generate_rent
    month = (params[:month] || Date.current.month).to_i
    year = (params[:year] || Date.current.year).to_i
    due_day = (params[:due_day] || 1).to_i

    result = @property.generate_monthly_rent(month: month, year: year, due_day: due_day)

    render_success(
      result,
      "Rent generation complete: #{result[:generated]} records created, #{result[:skipped]} skipped (already exist)",
      :ok
    )
  end

  private

  def set_property
    if admin_user?
      @property = Property.find(params[:id])
    else
      @property = Property.where(user_id: current_user.id).find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found('Property not found')
  end

  def require_admin
    render_forbidden('Admin access required') unless admin_user?
  end

  def authorize_property
    render_forbidden('Unauthorized') unless current_user.admin? || @property.user_id == current_user.id
  end

  def property_params
    params.require(:property).permit(:name, :address, :property_type, :status, :total_units, :user_id)
  end
end

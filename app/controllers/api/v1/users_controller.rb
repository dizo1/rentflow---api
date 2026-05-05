class Api::V1::UsersController < Api::V1::BaseController
  before_action :require_admin, only: [:index]
  before_action :set_user, only: [:show, :update, :destroy]
  before_action :authorize_user, only: [:update, :destroy]

  # GET /api/v1/users
  def index
    users = User.all
    render_success(
      users.as_json(only: [:id, :name, :email, :role]),
      'Users retrieved successfully'
    )
  end

  # GET /api/v1/users/:id
  def show
    render_success(
      @user.as_json(only: [:id, :name, :email, :role]),
      'User retrieved successfully'
    )
  end

  # GET /api/v1/profile
  def profile
    render_success(
      current_user.as_json(only: [:id, :name, :email, :role]),
      'Profile retrieved successfully'
    )
  end

  # PATCH /api/v1/profile
  def update_profile
    if current_user.update(profile_params)
      render_success(
        current_user.as_json(only: [:id, :name, :email, :role]),
        'Profile updated successfully'
      )
    else
      render_error('Update failed', :unprocessable_content, current_user.errors.full_messages)
    end
  end

  # PUT/PATCH /api/v1/users/:id
  def update
    if @user.update(user_params)
      render_success(
        @user.as_json(only: [:id, :name, :email, :role]),
        'User updated successfully'
      )
    else
      render_error('Update failed', :unprocessable_content, @user.errors.full_messages)
    end
  end

  # DELETE /api/v1/users/:id
  def destroy
    @user.destroy
    render_success(nil, 'User deleted successfully', :no_content)
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('User not found')
  end

  def authorize_user
    render_forbidden('Unauthorized') unless current_user.id == @user.id || admin_user?
  end

  def require_admin
    render_forbidden('Admin access required') unless admin_user?
  end

  def user_params
    params.require(:user).permit(:name, :email, :role)
  end

  def profile_params
    params.require(:user).permit(:name, :email, :password)
  end
end
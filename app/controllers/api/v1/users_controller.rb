class Api::V1::UsersController < Api::V1::BaseController
    before_action :require_admin, only: [:index]
    before_action :authorize_user, only: [:update, :destroy]

    def index
        users = User.all
        render_success(users.as_json(only: [:id, :name, :email, :role]), 'Users retrieved successfully')
    end

    def show
        user = User.find(params[:id])
        render_success(user.as_json(only: [:id, :name, :email, :role]), 'User retrieved successfully')
    rescue ActiveRecord::RecordNotFound
        render_not_found('User not found')
    end

    def profile
        render_success(current_user.as_json(only: [:id, :name, :email, :role]), 'Profile retrieved successfully')
    end

    def update
        user = User.find(params[:id])
        if user.update(user_params)
            render_success(user.as_json(only: [:id, :name, :email, :role]), 'User updated successfully')
        else
            render_error('Update failed', :unprocessable_content, user.errors.full_messages)
        end
    rescue ActiveRecord::RecordNotFound
        render_not_found('User not found')
    end

    def destroy
        user = User.find(params[:id])
        user.destroy
        render_success(nil, 'User deleted successfully', :no_content)
    rescue ActiveRecord::RecordNotFound
        render_not_found('User not found')
    end

    private

    def user_params
        params.require(:user).permit(:name, :email, :role)
    end

    def require_admin
        render_forbidden('Admin access required') unless admin_user?
    end

    def authorize_user
        user = User.find(params[:id])
        render_forbidden('Unauthorized') unless current_user.id == user.id || admin_user?
    end
end
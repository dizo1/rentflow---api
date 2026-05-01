module Api
  module V1
    class TenantsController < Api::V1::BaseController
      before_action :set_tenant, only: [ :show, :update, :destroy ]
      before_action :set_unit, only: [ :create, :show_by_unit ]
      before_action :authorize_tenant, only: [ :show, :update, :destroy, :create, :show_by_unit ]

      # GET /api/v1/tenants
      # List all tenants accessible to the current user
      def index
        tenants = if admin_user?
                    Tenant.all
        else
                    Tenant.joins(unit: :property).where(properties: { user_id: current_user.id })
        end

        render_success(
          tenants.as_json(
            only: [
              :id, :unit_id, :full_name, :phone, :email, :national_id,
              :move_in_date, :lease_start, :lease_end, :status, :emergency_contact, :created_at, :updated_at
            ]
          ),
          "Tenants retrieved successfully"
        )
      end

      # GET /api/v1/tenants/:id
      def show
        render_success(
          @tenant.as_json(
            only: [
              :id, :unit_id, :full_name, :phone, :email, :national_id,
              :move_in_date, :lease_start, :lease_end, :status, :emergency_contact, :created_at, :updated_at
            ]
          ),
          "Tenant retrieved successfully"
        )
      end

      # GET /api/v1/units/:unit_id/tenant
      # Get the tenant for a specific unit (has_one relationship)
      def show_by_unit
        tenant = @unit.tenant
        if tenant
          render_success(
            tenant.as_json(
              only: [
                :id, :unit_id, :full_name, :phone, :email, :national_id,
                :move_in_date, :lease_start, :lease_end, :status, :emergency_contact, :created_at, :updated_at
              ]
            ),
            "Tenant retrieved successfully"
          )
        else
          render_not_found("No tenant found for this unit")
        end
      end

      # POST /api/v1/units/:unit_id/tenant
      # Create a tenant for a specific unit
      def create
        # Ensure unit doesn't already have a tenant (has_one relationship)
        if @unit.tenant
          return render_error("Unit already has a tenant", :conflict)
        end

        tenant = @unit.build_tenant(tenant_params)
        if tenant.save
          render_success(
            tenant.as_json(
              only: [
                :id, :unit_id, :full_name, :phone, :email, :national_id,
                :move_in_date, :lease_start, :lease_end, :status, :emergency_contact, :created_at, :updated_at
              ]
            ),
            "Tenant created successfully",
            :created
          )
        else
          render_error("Validation failed", :unprocessable_content, tenant.errors.full_messages)
        end
      end

      # PUT/PATCH /api/v1/tenants/:id
      def update
        if @tenant.update(tenant_params)
          render_success(
            @tenant.as_json(
              only: [
                :id, :unit_id, :full_name, :phone, :email, :national_id,
                :move_in_date, :lease_start, :lease_end, :status, :emergency_contact, :created_at, :updated_at
              ]
            ),
            "Tenant updated successfully"
          )
        else
          render_error("Update failed", :unprocessable_content, @tenant.errors.full_messages)
        end
      end

      # DELETE /api/v1/tenants/:id
      def destroy
        @tenant.destroy
        render_success(nil, "Tenant deleted successfully", :no_content)
      end

      private

      def set_unit
        if admin_user?
          @unit = Unit.find(params[:unit_id])
        else
          @unit = Unit.joins(:property).where(properties: { user_id: current_user.id }).find(params[:unit_id])
        end
      rescue ActiveRecord::RecordNotFound
        render_not_found("Unit not found")
      end

      def set_tenant
        @tenant = Tenant.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found("Tenant not found")
      end

      def authorize_tenant
        # For direct tenant access, ensure ownership via unit's property
        tenant = @tenant || @unit&.tenant
        return unless tenant

        unless admin_user? || tenant.unit.property.user_id == current_user.id
          render_forbidden("Unauthorized")
        end
      end

      def tenant_params
        params.require(:tenant).permit(
          :full_name,
          :phone,
          :email,
          :national_id,
          :move_in_date,
          :lease_start,
          :lease_end,
          :status,
          :emergency_contact
        )
      end
    end
  end
end

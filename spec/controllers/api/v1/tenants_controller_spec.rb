require 'rails_helper'

RSpec.describe Api::V1::TenantsController, type: :controller do
  let!(:admin_user) { User.create(email: 'admin@example.com', password: 'password123', role: 'admin') }
  let!(:owner_user) { User.create(email: 'owner@example.com', password: 'password123', role: 'user') }
  let!(:other_user) { User.create(email: 'other@example.com', password: 'password123', role: 'user') }
  
  let!(:admin_property) do
    Property.create(
      user: admin_user,
      name: 'Admin Property',
      address: '123 Admin St',
      property_type: 'apartment',
      status: 'occupied',
      total_units: 3
    )
  end
  
  let!(:owner_property) do
    Property.create(
      user: owner_user,
      name: 'Owner Property',
      address: '456 Owner Ave',
      property_type: 'house',
      status: 'occupied',
      total_units: 2
    )
  end

  let!(:admin_unit) do
    admin_property.units.create(
      unit_number: 'A101',
      rent_amount: 1000,
      deposit_amount: 2000,
      occupancy_status: 'occupied'
    )
  end

  let!(:owner_unit) do
    owner_property.units.create(
      unit_number: 'B201',
      rent_amount: 1200,
      deposit_amount: 2400,
      occupancy_status: 'occupied'
    )
  end

  let!(:tenant) do
    Tenant.create!(
      unit: owner_unit,
      full_name: 'John Doe',
      phone: '555-1234',
      email: 'john@example.com',
      national_id: 'ID123456',
      move_in_date: Date.current,
      lease_start: Date.current,
      lease_end: 1.year.from_now.to_date,
      status: 'active',
      emergency_contact: 'Jane Doe: 555-5678'
    )
  end

  describe 'authentication & authorization' do
    context 'as admin' do
      before { sign_in_admin }

      it 'can index all tenants' do
        get :index
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data'].length).to be >= 1
      end

      it 'can show any tenant' do
        get :show, params: { id: tenant.id }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'as property owner' do
      before { sign_in_owner }

      it 'can index tenants for own properties' do
        get :index
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
      end

      it 'cannot show tenant from other property' do
        get :show, params: { id: tenant.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'can create tenant for own unit' do
        post :create, params: {
          unit_id: owner_unit.id,
          tenant: {
            full_name: 'New Tenant',
            phone: '555-9999',
            email: 'new@example.com',
            move_in_date: Date.current,
            lease_start: Date.current,
            lease_end: 1.year.from_now.to_date,
            status: 'pending_move_in'
          }
        }
        expect(response).to have_http_status(:created)
      end

      it 'cannot create tenant for other owner unit' do
        post :create, params: {
          unit_id: admin_unit.id,
          tenant: {
            full_name: 'Bad Tenant',
            phone: '555-0000',
            move_in_date: Date.current,
            lease_start: Date.current,
            lease_end: 1.year.from_now.to_date,
            status: 'pending_move_in'
          }
        }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'as regular user' do
      before { sign_in_other }

      it 'cannot access tenant resources' do
        get :index
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'CRUD operations' do
    before { sign_in_owner }

    describe 'GET #index' do
      it 'returns tenants for accessible units' do
        get :index
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']).to be_an(Array)
      end
    end

    describe 'GET #show' do
      it 'returns tenant details' do
        get :show, params: { id: tenant.id }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']['full_name']).to eq('John Doe')
        expect(json['data']['phone']).to eq('555-1234')
      end

      it 'returns not found for non-existent tenant' do
        get :show, params: { id: 99999 }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET #show_by_unit' do
      it 'returns tenant for specified unit' do
        get :show_by_unit, params: { unit_id: owner_unit.id }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']['full_name']).to eq('John Doe')
      end

      it 'returns not found when unit has no tenant' do
        vacant_unit = owner_property.units.create(
          unit_number: 'B202',
          rent_amount: 1100,
          deposit_amount: 2200,
          occupancy_status: 'vacant'
        )
        get :show_by_unit, params: { unit_id: vacant_unit.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'POST #create' do
      it 'creates a tenant with valid params' do
        expect {
          post :create, params: {
            unit_id: owner_unit.id,
            tenant: {
              full_name: 'Alice Smith',
              phone: '555-7777',
              email: 'alice@example.com',
              national_id: 'ID789',
              move_in_date: Date.current,
              lease_start: Date.current,
              lease_end: 1.year.from_now.to_date,
              status: 'pending_move_in',
              emergency_contact: 'Bob: 555-8888'
            }
          }
        }.to change(Tenant, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it 'fails when unit already has a tenant (has_one constraint)' do
        post :create, params: {
          unit_id: owner_unit.id,
          tenant: {
            full_name: 'Another Tenant',
            phone: '555-1111',
            move_in_date: Date.current,
            lease_start: Date.current,
            lease_end: 1.year.from_now.to_date,
            status: 'pending_move_in'
          }
        }
        expect(response).to have_http_status(:conflict)
      end

      it 'fails with invalid params' do
        post :create, params: {
          unit_id: owner_unit.id,
          tenant: {
            full_name: '',
            phone: '',
            move_in_date: nil,
            lease_start: Date.current,
            lease_end: 1.year.from_now.to_date,
            status: 'invalid'
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end
    end

    describe 'PUT #update' do
      it 'updates tenant details' do
        put :update, params: {
          id: tenant.id,
          tenant: {
            phone: '555-9999',
            status: 'vacated'
          }
        }
        expect(response).to have_http_status(:ok)
        tenant.reload
        expect(tenant.phone).to eq('555-9999')
        expect(tenant.status).to eq('vacated')
      end

      it 'fails with invalid update' do
        put :update, params: {
          id: tenant.id,
          tenant: { status: 'invalid_status' }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe 'DELETE #destroy' do
      it 'deletes the tenant' do
        delete :destroy, params: { id: tenant.id }
        expect(response).to have_http_status(:no_content)
        expect(Tenant.find_by(id: tenant.id)).to be_nil
      end
    end
  end

  describe 'unit occupancy callback' do
    it 'sets unit to occupied when tenant status becomes active' do
      vacated_tenant = Tenant.create!(
        unit: owner_unit,
        full_name: 'Jane Doe',
        phone: '555-2222',
        move_in_date: Date.current,
        lease_start: Date.current,
        lease_end: 1.year.from_now.to_date,
        status: 'vacated'
      )
      owner_unit.reload
      expect(owner_unit.occupancy_status).to eq('vacant')

      vacated_tenant.update!(status: 'active')
      expect(owner_unit.reload.occupancy_status).to eq('occupied')
    end
  end

  private

  def sign_in_admin
    request.headers['Authorization'] = "Bearer #{admin_user.generate_jwt}"
    @current_user = admin_user
  end

  def sign_in_owner
    request.headers['Authorization'] = "Bearer #{owner_user.generate_jwt}"
    @current_user = owner_user
  end

  def sign_in_other
    request.headers['Authorization'] = "Bearer #{other_user.generate_jwt}"
    @current_user = other_user
  end
end

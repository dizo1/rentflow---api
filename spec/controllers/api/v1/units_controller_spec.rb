require 'rails_helper'

RSpec.describe Api::V1::UnitsController, type: :controller do
  let!(:user) { User.create(email: 'user@example.com', password: 'password123') }
  let!(:admin) { User.create(email: 'admin@example.com', password: 'password123', role: 'admin') }
  let!(:property) { Property.create(user: user, name: 'Test Property', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 5) }
  let!(:other_user) { User.create(email: 'other@example.com', password: 'password123') }
  let!(:other_property) { Property.create(user: other_user, name: 'Other Property', address: '456 Ave', property_type: 'house', status: 'vacant', total_units: 3) }
  let(:user_token) { user.generate_jwt }
  let(:admin_token) { admin.generate_jwt }

  before do
    request.headers['Authorization'] = "Bearer #{user_token}"
  end

  describe 'GET #index' do
    it 'requires admin for property units listing' do
      get :index, params: { property_id: property.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns units for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :index, params: { property_id: property.id }
      expect(response).to have_http_status(:ok)
    end

    it 'returns empty array when no units exist' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :index, params: { property_id: property.id }
      expect(JSON.parse(response.body)['data']).to eq([])
    end
  end

  describe 'POST #create' do
    it 'requires admin' do
      post :create, params: { property_id: property.id, unit: { unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied' } }
      expect(response).to have_http_status(:forbidden)
    end

    it 'creates a unit as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      post :create, params: { property_id: property.id, unit: { unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied' } }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['data']['unit_number']).to eq('101')
    end

    it 'returns errors for invalid data' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      post :create, params: { property_id: property.id, unit: { unit_number: '', rent_amount: -100 } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns not found for non-existent property' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      post :create, params: { property_id: 99999, unit: { unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied' } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #show' do
    let!(:unit) { property.units.create(unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied') }

    it 'returns unit for owner' do
      get :show, params: { id: unit.id }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['data']['unit_number']).to eq('101')
    end

    it 'returns unit for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :show, params: { id: unit.id }
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access for other users' do
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      get :show, params: { id: unit.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns not found for non-existent unit' do
      get :show, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PUT #update' do
    let!(:unit) { property.units.create(unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied') }

    it 'updates as owner' do
      put :update, params: { id: unit.id, unit: { rent_amount: 1300 } }
      expect(response).to have_http_status(:ok)
      expect(unit.reload.rent_amount.to_f).to eq(1300.0)
    end

    it 'updates as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      put :update, params: { id: unit.id, unit: { deposit_amount: 2600 } }
      expect(response).to have_http_status(:ok)
      expect(unit.reload.deposit_amount.to_f).to eq(2600.0)
    end

    it 'forbids update by other users' do
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      put :update, params: { id: unit.id, unit: { rent_amount: 9999 } }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns errors for invalid data' do
      put :update, params: { id: unit.id, unit: { occupancy_status: 'invalid_status' } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'DELETE #destroy' do
    let!(:unit) { property.units.create(unit_number: '101', rent_amount: 1200, deposit_amount: 2400, occupancy_status: 'occupied') }

    it 'deletes as owner' do
      expect { delete :destroy, params: { id: unit.id } }.to change { Unit.count }.by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it 'deletes as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      expect { delete :destroy, params: { id: unit.id } }.to change { Unit.count }.by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it 'forbids delete by other users' do
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      delete :destroy, params: { id: unit.id }
      expect(response).to have_http_status(:forbidden)
    end
  end
end

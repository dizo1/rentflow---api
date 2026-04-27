require 'rails_helper'

RSpec.describe Api::V1::PropertiesController, type: :controller do
  let!(:user) { User.create(email: 'user@example.com', password: 'password123') }
  let!(:admin) { User.create(email: 'admin@example.com', password: 'password123', role: 'admin') }
  let(:user_token) { user.generate_jwt }
  let(:admin_token) { admin.generate_jwt }

  before do
    request.headers['Authorization'] = "Bearer #{user_token}"
  end

  describe 'GET #index' do
    it 'requires admin' do
      get :index
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns properties for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    it 'requires admin' do
      post :create, params: { property: { name: 'Test', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 5, user_id: user.id } }
      expect(response).to have_http_status(:forbidden)
    end

    it 'creates a property as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      post :create, params: { property: { name: 'Test', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 5, user_id: user.id } }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['data']['name']).to eq('Test')
    end

    it 'returns errors for invalid data' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      post :create, params: { property: { name: '', address: '123 St' } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'GET #show' do
    let!(:property) { Property.create(user: user, name: 'My Property', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 10) }

    it 'returns property for owner' do
      get :show, params: { id: property.id }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['data']['name']).to eq('My Property')
    end

    it 'returns property for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :show, params: { id: property.id }
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access for other users' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      get :show, params: { id: property.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns not found for non-existent property' do
      get :show, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PUT #update' do
    let!(:property) { Property.create(user: user, name: 'Old', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 10) }

    it 'updates as owner' do
      put :update, params: { id: property.id, property: { name: 'Updated' } }
      expect(response).to have_http_status(:ok)
      expect(property.reload.name).to eq('Updated')
    end

    it 'updates as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      put :update, params: { id: property.id, property: { name: 'Admin Updated' } }
      expect(response).to have_http_status(:ok)
      expect(property.reload.name).to eq('Admin Updated')
    end

    it 'forbids update by other users' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      put :update, params: { id: property.id, property: { name: 'Hacked' } }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE #destroy' do
    let!(:property) { Property.create(user: user, name: 'My Property', address: '123 St', property_type: 'apartment', status: 'vacant', total_units: 10) }

    it 'deletes as owner' do
      delete :destroy, params: { id: property.id }
      expect(response).to have_http_status(:no_content)
      expect(Property.exists?(property.id)).to be false
    end

    it 'deletes as admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      delete :destroy, params: { id: property.id }
      expect(response).to have_http_status(:no_content)
    end

    it 'forbids delete by other users' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_token = other_user.generate_jwt
      request.headers['Authorization'] = "Bearer #{other_token}"
      delete :destroy, params: { id: property.id }
      expect(response).to have_http_status(:forbidden)
    end
  end
end

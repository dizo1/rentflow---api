require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
  let!(:user) { User.create(email: 'user@example.com', password: 'password123') }
  let!(:admin) { User.create(email: 'admin@example.com', password: 'password123', role: 'admin') }
  let(:user_token) { user.generate_jwt }
  let(:admin_token) { admin.generate_jwt }

  before do
    request.headers['Authorization'] = "Bearer #{user_token}"
  end

  describe 'GET #profile' do
    it 'returns current user' do
      get :profile
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['data']['email']).to eq('user@example.com')
    end
  end

  describe 'GET #index' do
    it 'requires admin' do
      get :index
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns users for admin' do
      request.headers['Authorization'] = "Bearer #{admin_token}"
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['data'].length).to eq(2)
    end
  end

  describe 'GET #show' do
    it 'returns user' do
      get :show, params: { id: user.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PUT #update' do
    it 'updates own profile' do
      put :update, params: { id: user.id, user: { name: 'Updated Name' } }
      expect(response).to have_http_status(:ok)
      user.reload
      expect(user.name).to eq('Updated Name')
    end

    it 'cannot update others' do
      put :update, params: { id: admin.id, user: { name: 'Hacked' } }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE #destroy' do
    it 'cannot delete others' do
      delete :destroy, params: { id: admin.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'can delete self' do
      delete :destroy, params: { id: user.id }
      expect(response).to have_http_status(:no_content)
    end
  end
end
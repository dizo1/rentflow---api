require 'rails_helper'

RSpec.describe Api::V1::AuthController, type: :controller do
  describe 'POST #signup' do
    it 'creates a new user' do
      post :signup, params: { user: { email: 'new@example.com', password: 'password123', name: 'New User' } }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['data']['user']['email']).to eq('new@example.com')
    end

    it 'returns errors for invalid data' do
      post :signup, params: { user: { email: '', password: 'password123' } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'POST #login' do
    let!(:user) { User.create(email: 'test@example.com', password: 'password123') }

    it 'logs in with valid credentials' do
      post :login, params: { user: { email: 'test@example.com', password: 'password123' } }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['data']['token']).to be_present
    end

    it 'returns error for invalid credentials' do
      post :login, params: { user: { email: 'test@example.com', password: 'wrong' } }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
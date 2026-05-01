require 'rails_helper'

RSpec.describe Api::V1::NotificationsController, type: :controller do
  let!(:user) { User.create(email: 'user@example.com', password: 'password123', name: 'Test User') }
  let!(:other_user) { User.create(email: 'other@example.com', password: 'password123') }
  let!(:user_token) { user.generate_jwt }

  before do
    request.headers['Authorization'] = "Bearer #{user_token}"
  end

  describe 'GET #index' do
    it 'returns notifications for the authenticated user' do
      notification = Notification.create!(
        user: user,
        title: 'Test Notification',
        message: 'This is a test notification',
        notification_type: 'test'
      )

      get :index

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data'].length).to eq(1)
      expect(json['data'].first['id']).to eq(notification.id)
    end

    it 'does not return notifications for other users' do
      other_notification = Notification.create!(
        user: other_user,
        title: 'Other Notification',
        message: 'This is another test notification',
        notification_type: 'test'
      )

      get :index

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data'].length).to eq(0)
    end
  end

  describe 'GET #show' do
    it 'returns the notification if it belongs to the authenticated user' do
      notification = Notification.create!(
        user: user,
        title: 'Test Notification',
        message: 'This is a test notification',
        notification_type: 'test'
      )

      get :show, params: { id: notification.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['id']).to eq(notification.id)
    end

    it 'returns not found if notification does not belong to the authenticated user' do
      other_notification = Notification.create!(
        user: other_user,
        title: 'Other Notification',
        message: 'This is another test notification',
        notification_type: 'test'
      )

      get :show, params: { id: other_notification.id }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    it 'creates a notification for the authenticated user' do
      notification_params = {
        title: 'New Notification',
        message: 'New notification message',
        notification_type: 'test'
      }

      expect {
        post :create, params: { notification: notification_params }
      }.to change(Notification, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['title']).to eq('New Notification')
    end

    it 'returns error for invalid notification data' do
      notification_params = {
        # missing title
        message: 'Test message',
        notification_type: 'test'
      }

      post :create, params: { notification: notification_params }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['success']).to be false
      expect(json['error']).to include("can't be blank")
    end
  end

  describe 'PATCH #update' do
    it 'updates the notification if it belongs to the authenticated user' do
      notification = Notification.create!(
        user: user,
        title: 'Original Title',
        message: 'Original message',
        notification_type: 'test'
      )

      update_params = { title: 'Updated Title' }

      patch :update, params: { id: notification.id, notification: update_params }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['data']['title']).to eq('Updated Title')
      expect(notification.reload.title).to eq('Updated Title')
    end

    it 'returns not found if notification does not belong to the authenticated user' do
      other_notification = Notification.create!(
        user: other_user,
        title: 'Other Notification',
        message: 'This is another test notification',
        notification_type: 'test'
      )

      patch :update, params: { id: other_notification.id, notification: { title: 'Updated' } }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the notification if it belongs to the authenticated user' do
      notification = Notification.create!(
        user: user,
        title: 'Test Notification',
        message: 'This is a test notification',
        notification_type: 'test'
      )

      expect {
        delete :destroy, params: { id: notification.id }
      }.to change(Notification, :count).by(-1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end

    it 'returns not found if notification does not belong to the authenticated user' do
      other_notification = Notification.create!(
        user: other_user,
        title: 'Other Notification',
        message: 'This is another test notification',
        notification_type: 'test'
      )

      delete :destroy, params: { id: other_notification.id }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH #read' do
    it 'marks the notification as read if it belongs to the authenticated user' do
      notification = Notification.create!(
        user: user,
        title: 'Test Notification',
        message: 'This is a test notification',
        notification_type: 'test'
      )

      expect(notification.read_status).to be false

      patch :read, params: { id: notification.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(notification.reload.read_status).to be true
    end

    it 'returns not found if notification does not belong to the authenticated user' do
      other_notification = Notification.create!(
        user: other_user,
        title: 'Other Notification',
        message: 'This is another test notification',
        notification_type: 'test'
      )

      patch :read, params: { id: other_notification.id }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH #unread' do
    it 'marks the notification as unread if it belongs to the authenticated user' do
      notification = Notification.create!(
        user: user,
        title: 'Test Notification',
        message: 'This is a test notification',
        notification_type: 'test',
        read_status: true
      )

      patch :unread, params: { id: notification.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(notification.reload.read_status).to be false
    end

    it 'returns not found if notification does not belong to the authenticated user' do
      other_notification = Notification.create!(
        user: other_user,
        title: 'Other Notification',
        message: 'This is another test notification',
        notification_type: 'test',
        read_status: true
      )

      patch :unread, params: { id: other_notification.id }

      expect(response).to have_http_status(:not_found)
    end
  end
end
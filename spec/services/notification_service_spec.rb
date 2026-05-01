require 'rails_helper'

RSpec.describe NotificationService, type: :service do
  let(:user) { User.create(email: 'user@example.com', password: 'password123', name: 'Test User') }
  let(:service) { NotificationService.new(user) }

  describe '#create_notification' do
    it 'creates a notification for the user' do
      expect {
        service.create_notification(
          title: 'Test Title',
          message: 'Test message',
          notification_type: 'test'
        )
      }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.user).to eq(user)
      expect(notification.title).to eq('Test Title')
      expect(notification.message).to eq('Test message')
      expect(notification.notification_type).to eq('test')
      expect(notification.read_status).to be false
    end

    it 'allows setting read_status' do
      service.create_notification(
        title: 'Test Title',
        message: 'Test message',
        notification_type: 'test',
        read_status: true
      )

      notification = Notification.last
      expect(notification.read_status).to be true
    end
  end

  describe '#mark_as_read' do
    it 'marks the notification as read if it belongs to the user' do
      notification = Notification.create!(
        user: user,
        title: 'Test Notification',
        message: 'This is a test notification',
        notification_type: 'test'
      )

      expect(notification.read_status).to be false

      service.mark_as_read(notification.id)

      expect(notification.reload.read_status).to be true
    end

    it 'does not mark notification as read if it does not belong to the user' do
      other_user = User.create(email: 'other@example.com', password: 'password123')
      other_notification = Notification.create!(
        user: other_user,
        title: 'Other Notification',
        message: 'This is another test notification',
        notification_type: 'test'
      )

      service.mark_as_read(other_notification.id)

      expect(other_notification.reload.read_status).to be false
    end
  end

  describe '#unread_count' do
    it 'returns the count of unread notifications for the user' do
      Notification.create!(user: user, title: 'Unread 1', message: 'Test', notification_type: 'test')
      Notification.create!(user: user, title: 'Unread 2', message: 'Test', notification_type: 'test')
      Notification.create!(user: user, title: 'Read', message: 'Test', notification_type: 'test', read_status: true)

      expect(service.unread_count).to eq(2)
    end
  end
end
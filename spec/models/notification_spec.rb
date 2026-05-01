require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:user) { User.create(email: 'user@example.com', password: 'password123', name: 'Test User') }

  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    context 'with valid attributes' do
      it 'is valid' do
        notification = Notification.new(
          user: user,
          title: 'Test Notification',
          message: 'This is a test notification',
          notification_type: 'test'
          # read_status is not set, but should default to false via after_initialize
        )
        expect(notification).to be_valid
        expect(notification.read_status).to be false
      end
    end

    context 'title' do
      it 'is invalid without title' do
        notification = Notification.new(
          user: user,
          message: 'Test message',
          notification_type: 'test'
        )
        expect(notification).not_to be_valid
        expect(notification.errors[:title]).to include("can't be blank")
      end
    end

    context 'message' do
      it 'is invalid without message' do
        notification = Notification.new(
          user: user,
          title: 'Test Title',
          notification_type: 'test'
        )
        expect(notification).not_to be_valid
        expect(notification.errors[:message]).to include("can't be blank")
      end
    end

    context 'notification_type' do
      it 'is invalid without notification_type' do
        notification = Notification.new(
          user: user,
          title: 'Test Title',
          message: 'Test message'
        )
        expect(notification).not_to be_valid
        expect(notification.errors[:notification_type]).to include("can't be blank")
      end
    end

    context 'read_status' do
      it 'is valid when read_status is true' do
        notification = Notification.new(
          user: user,
          title: 'Test Title',
          message: 'Test message',
          notification_type: 'test',
          read_status: true
        )
        expect(notification).to be_valid
      end
      
      it 'is valid when read_status is false' do
        notification = Notification.new(
          user: user,
          title: 'Test Title',
          message: 'Test message',
          notification_type: 'test',
          read_status: false
        )
        expect(notification).to be_valid
      end
      
      it 'is invalid when read_status is neither true nor false' do
        notification = Notification.new(
          user: user,
          title: 'Test Title',
          message: 'Test message',
          notification_type: 'test',
          read_status: nil
        )
        expect(notification).not_to be_valid
        expect(notification.errors[:read_status]).to include("is not included in the list")
      end
    end
  end

  describe 'scopes' do
    describe '.for_user' do
      it 'returns notifications for the given user' do
        notification = Notification.create!(
          user: user,
          title: 'Test Notification',
          message: 'This is a test notification',
          notification_type: 'test'
          # read_status will default to false
        )

        expect(Notification.for_user(user.id)).to include(notification)
      end

      it 'does not return notifications for other users' do
        other_user = User.create(email: 'other@example.com', password: 'password123')
        other_notification = Notification.create!(
          user: other_user,
          title: 'Other Notification',
          message: 'This is another test notification',
          notification_type: 'test'
        )

        expect(Notification.for_user(user.id)).not_to include(other_notification)
      end
    end

    describe '.unread' do
      it 'returns only unread notifications' do
        unread_notification = Notification.create!(
          user: user,
          title: 'Unread Notification',
          message: 'This is an unread notification',
          notification_type: 'test'
          # read_status will default to false
        )
        read_notification = Notification.create!(
          user: user,
          title: 'Read Notification',
          message: 'This is a read notification',
          notification_type: 'test',
          read_status: true
        )

        expect(Notification.unread).to include(unread_notification)
        expect(Notification.unread).not_to include(read_notification)
      end
    end
  end
end
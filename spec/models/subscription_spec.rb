require 'rails_helper'

RSpec.describe Subscription, type: :model do
  let(:user) { User.create(email: 'test@example.com', password: 'password123') }

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:plan) }
    it { should validate_presence_of(:status) }
    it { should validate_numericality_of(:sms_used).is_greater_than_or_equal_to(0) }
  end

  describe 'enums' do
    it { should define_enum_for(:plan).with_values(trial: 0, basic: 1, pro: 2) }
    it { should define_enum_for(:status).with_values(trialing: 0, active: 1, expired: 2, cancelled: 3, suspended: 4) }
  end

  describe '#expired?' do
    context 'when trialing and trial not ended' do
      let(:subscription) { Subscription.new(status: :trialing, trial_ends_at: 1.day.from_now) }
      it { expect(subscription.expired?).to be_falsey }
    end

    context 'when trialing and trial ended' do
      let(:subscription) { Subscription.new(status: :trialing, trial_ends_at: 1.day.ago) }
      it { expect(subscription.expired?).to be_truthy }
    end

    context 'when active' do
      let(:subscription) { Subscription.new(status: :active) }
      it { expect(subscription.expired?).to be_falsey }
    end

    context 'when expired' do
      let(:subscription) { Subscription.new(status: :expired) }
      it { expect(subscription.expired?).to be_falsey }
    end

    context 'when ends_at passed' do
      let(:subscription) { Subscription.new(status: :active, ends_at: 1.day.ago) }
      it { expect(subscription.expired?).to be_truthy }
    end
  end

  describe '#check_and_expire!' do
    context 'when not expired' do
      let(:subscription) { Subscription.create(user: user, plan: :trial, status: :trialing, trial_ends_at: 1.day.from_now) }
      it 'does not change status' do
        expect { subscription.check_and_expire! }.not_to change(subscription, :status)
      end
    end

    context 'when expired' do
      let(:subscription) { Subscription.create(user: user, plan: :trial, status: :trialing, trial_ends_at: 1.day.ago) }
      it 'changes status to expired' do
        expect { subscription.check_and_expire! }.to change(subscription, :status).to('expired')
      end
    end
  end
end

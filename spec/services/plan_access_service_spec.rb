require 'rails_helper'

RSpec.describe PlanAccessService, type: :service do
  let(:user) { instance_double(User, admin?: false, properties: double(count: 0), units: double(count: 0)) }
  let(:subscription) { instance_double(Subscription, plan: :trial, status: :trialing, sms_used: 0, check_and_expire!: nil, active?: false, trialing?: true) }

  before do
    allow(user).to receive(:subscription).and_return(subscription)
  end

  describe '.can_create_property?' do
    context 'when user is admin' do
      let(:user) { instance_double(User, admin?: true) }
      it { expect(PlanAccessService.can_create_property?(user)).to be_truthy }
    end

    context 'when trial user with available properties' do
      it { expect(PlanAccessService.can_create_property?(user)).to be_truthy }
    end

    context 'when basic user' do
      let(:subscription) { instance_double(Subscription, plan: :basic, status: :active, sms_used: 0, check_and_expire!: nil, active?: true, trialing?: false) }
      it { expect(PlanAccessService.can_create_property?(user)).to be_truthy }
    end
  end

  describe '.can_send_sms?' do
    context 'when user is admin' do
      let(:user) { instance_double(User, admin?: true) }
      it { expect(PlanAccessService.can_send_sms?(user)).to be_truthy }
    end

    context 'when trial user with available SMS' do
      it { expect(PlanAccessService.can_send_sms?(user)).to be_truthy }
    end

    context 'when user has used all SMS' do
      let(:subscription) { instance_double(Subscription, plan: :trial, status: :trialing, sms_used: 20, check_and_expire!: nil, active?: false, trialing?: true) }
      it { expect(PlanAccessService.can_send_sms?(user)).to be_falsey }
    end
  end

  describe '.can_access_advanced_analytics?' do
    context 'when user is admin' do
      let(:user) { instance_double(User, admin?: true) }
      it { expect(PlanAccessService.can_access_advanced_analytics?(user)).to be_truthy }
    end

    context 'when trial user' do
      it { expect(PlanAccessService.can_access_advanced_analytics?(user)).to be_falsey }
    end

    context 'when pro user' do
      let(:subscription) { instance_double(Subscription, plan: :pro, status: :active, sms_used: 0, check_and_expire!: nil, active?: true, trialing?: false) }
      it { expect(PlanAccessService.can_access_advanced_analytics?(user)).to be_truthy }
    end
  end
end
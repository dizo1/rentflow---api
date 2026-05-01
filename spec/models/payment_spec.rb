require 'rails_helper'

RSpec.describe Payment, type: :model do
  let(:user) { User.create(email: 'test@example.com', password: 'password123') }

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).is_greater_than(0) }
    it { should validate_presence_of(:plan) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:reference) }
  end

  describe 'enums' do
    it { should define_enum_for(:plan).with_values(basic: 0, pro: 1) }
    it { should define_enum_for(:status).with_values(pending: 0, successful: 1, failed: 2) }
  end
end

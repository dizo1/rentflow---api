
require 'rails_helper'

RSpec.describe User, type: :model do
  it "is valid with email and password" do
    user = User.new(email: "test@example.com", password: "password123")
    expect(user).to be_valid
  end

  it "is invalid without email" do
    user = User.new(password: "password123")
    expect(user).not_to be_valid
  end

  it "is invalid without password" do
    user = User.new(email: "test@example.com")
    expect(user).not_to be_valid
  end

  it "is invalid with short password" do
    user = User.new(email: "test@example.com", password: "123")
    expect(user).not_to be_valid
  end

  it "has default role of user" do
    user = User.create(email: "test@example.com", password: "password123")
    expect(user.role).to eq('user')
  end

  it "can be admin" do
    user = User.create(email: "admin@example.com", password: "password123", role: 'admin')
    expect(user.admin?).to be true
  end

  it "generates JWT token" do
    user = User.create(email: "test@example.com", password: "password123")
    token = user.generate_jwt
    expect(token).to be_present
    decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
    expect(decoded['user_id']).to eq(user.id)
  end

  it "has many properties" do
    association = described_class.reflect_on_association(:properties)

    expect(association.macro).to eq(:has_many)
  end
end
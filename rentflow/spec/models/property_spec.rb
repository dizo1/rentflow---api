require 'rails_helper'

RSpec.describe Property, type: :model do
  it 'is valid with all required attributes' do
    user = User.create(email: 'owner@example.com', password: 'password123')
    property = Property.new(
      user: user,
      name: 'Riverfront Apartments',
      property_type: 'apartment',
      address: '123 Main St',
      status: 'vacant',
      total_units: 12
    )

    expect(property).to be_valid
  end

  it 'belongs to a user' do
    association = described_class.reflect_on_association(:user)

    expect(association.macro).to eq(:belongs_to)
  end

  it 'supports property type enum values' do
    expect(Property.property_types.keys).to match_array(%w[rentals apartment house commercial])
  end

  it 'supports status enum values' do
    expect(Property.statuses.keys).to match_array(%w[occupied vacant])
  end

  it 'is invalid without a user' do
    property = Property.new(
      name: 'Riverfront Apartments',
      property_type: 'apartment',
      address: '123 Main St',
      status: 'occupied',
      total_units: 12
    )

    expect(property).not_to be_valid
    expect(property.errors[:user]).to include("must exist")
  end

  it 'validates presence for required attributes' do
    property = Property.new(user: User.create(email: 'owner@example.com', password: 'password123'))

    expect(property).not_to be_valid
    expect(property.errors[:name]).to include("can't be blank")
    expect(property.errors[:property_type]).to include("can't be blank")
    expect(property.errors[:address]).to include("can't be blank")
    expect(property.errors[:status]).to include("can't be blank")
    expect(property.errors[:total_units]).to include("can't be blank")
  end

  it 'validates total_units is a non-negative integer' do
    property = Property.new(
      user: User.create(email: 'owner@example.com', password: 'password123'),
      name: 'Riverfront Apartments',
      property_type: 'apartment',
      address: '123 Main St',
      status: 'vacant',
      total_units: -1
    )

    expect(property).not_to be_valid
    expect(property.errors[:total_units]).to include('must be greater than or equal to 0')
  end
end

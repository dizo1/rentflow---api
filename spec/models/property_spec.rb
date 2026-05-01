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
      property_status: 'pending',
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

  it 'supports property_status enum values' do
    expect(Property.property_statuses.keys).to match_array(%w[pending in_progress resolved cancelled])
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
      property_status: 'pending',
      total_units: -1
    )

    expect(property).not_to be_valid
    expect(property.errors[:total_units]).to include('must be greater than or equal to 0')
  end

  describe 'property_status scopes' do
    let!(:user) { User.create(email: 'owner@example.com', password: 'password123') }
    let!(:pending_property) { Property.create(user: user, name: 'Pending Property', property_type: 'apartment', address: '123 St', status: 'vacant', property_status: 'pending', total_units: 5) }
    let!(:in_progress_property) { Property.create(user: user, name: 'In Progress Property', property_type: 'apartment', address: '456 St', status: 'vacant', property_status: 'in_progress', total_units: 5) }
    let!(:resolved_property) { Property.create(user: user, name: 'Resolved Property', property_type: 'apartment', address: '789 St', status: 'vacant', property_status: 'resolved', total_units: 5) }
    let!(:cancelled_property) { Property.create(user: user, name: 'Cancelled Property', property_type: 'apartment', address: '101 St', status: 'vacant', property_status: 'cancelled', total_units: 5) }

    it '.pending returns only pending properties' do
      expect(Property.pending).to match_array([pending_property])
    end

    it '.in_progress returns only in_progress properties' do
      expect(Property.in_progress).to match_array([in_progress_property])
    end

    it '.resolved returns only resolved properties' do
      expect(Property.resolved).to match_array([resolved_property])
    end

    it '.cancelled returns only cancelled properties' do
      expect(Property.cancelled).to match_array([cancelled_property])
    end
  end
end

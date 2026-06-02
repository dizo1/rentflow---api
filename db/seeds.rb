puts "Cleaning up existing demo data..."
demo_user = User.find_by(email: "demo@rentflow.com")
if demo_user
  RentPayment.where(landlord_id: demo_user.id).destroy_all rescue nil
  Tenant.where(unit_id: Unit.joins(:property).where(properties: { user_id: demo_user.id }).pluck(:id)).destroy_all
  Unit.joins(:property).where(properties: { user_id: demo_user.id }).destroy_all
  Property.where(user_id: demo_user.id).destroy_all
  demo_user.destroy
end

puts "Creating demo user..."
user = User.create!(
  email:    "demo@rentflow.com",
  password: "Demo1234!",
  name:     "Demo Landlord",
  role:     "user"
)

puts "Creating properties..."
sunset = Property.create!(
  user_id:       user.id,
  name:          "Sunset Apartments",
  address:       "123 Ngong Road, Nairobi",
  property_type: "apartment",
  status:        "occupied",
  total_units:   8
)

greenview = Property.create!(
  user_id:       user.id,
  name:          "Greenview Court",
  address:       "45 Thika Road, Nairobi",
  property_type: "apartment",
  status:        "occupied",
  total_units:   6
)

lakeside = Property.create!(
  user_id:       user.id,
  name:          "Lakeside Residences",
  address:       "8 Nyali Road, Mombasa",
  property_type: "apartment",
  status:        "occupied",
  total_units:   4
)

puts "Creating units..."
sunset_units = [
  { unit_number: "A1", rent_amount: 25000, deposit_amount: 50000, occupancy_status: "occupied" },
  { unit_number: "A2", rent_amount: 25000, deposit_amount: 50000, occupancy_status: "occupied" },
  { unit_number: "A3", rent_amount: 25000, deposit_amount: 50000, occupancy_status: "vacant"   },
  { unit_number: "B1", rent_amount: 28000, deposit_amount: 56000, occupancy_status: "occupied" },
  { unit_number: "B2", rent_amount: 28000, deposit_amount: 56000, occupancy_status: "occupied" },
  { unit_number: "B3", rent_amount: 28000, deposit_amount: 56000, occupancy_status: "vacant"   },
  { unit_number: "C1", rent_amount: 32000, deposit_amount: 64000, occupancy_status: "occupied" },
  { unit_number: "C2", rent_amount: 32000, deposit_amount: 64000, occupancy_status: "occupied" },
].map { |u| Unit.create!(property_id: sunset.id, **u) }

greenview_units = [
  { unit_number: "G1", rent_amount: 18000, deposit_amount: 36000, occupancy_status: "occupied" },
  { unit_number: "G2", rent_amount: 18000, deposit_amount: 36000, occupancy_status: "occupied" },
  { unit_number: "G3", rent_amount: 20000, deposit_amount: 40000, occupancy_status: "occupied" },
  { unit_number: "G4", rent_amount: 20000, deposit_amount: 40000, occupancy_status: "vacant"   },
  { unit_number: "G5", rent_amount: 22000, deposit_amount: 44000, occupancy_status: "occupied" },
  { unit_number: "G6", rent_amount: 22000, deposit_amount: 44000, occupancy_status: "occupied" },
].map { |u| Unit.create!(property_id: greenview.id, **u) }

lakeside_units = [
  { unit_number: "L1", rent_amount: 35000, deposit_amount: 70000, occupancy_status: "occupied" },
  { unit_number: "L2", rent_amount: 35000, deposit_amount: 70000, occupancy_status: "occupied" },
  { unit_number: "L3", rent_amount: 40000, deposit_amount: 80000, occupancy_status: "occupied" },
  { unit_number: "L4", rent_amount: 40000, deposit_amount: 80000, occupancy_status: "vacant"   },
].map { |u| Unit.create!(property_id: lakeside.id, **u) }

puts "Creating tenants..."
tenants_data = [
  { full_name: "James Mwangi",    email: "james.mwangi@email.com",    phone: "+254711001001", national_id: "23456781", unit: sunset_units[0] },
  { full_name: "Amina Hassan",    email: "amina.hassan@email.com",    phone: "+254711001002", national_id: "23456782", unit: sunset_units[1] },
  { full_name: "Brian Otieno",    email: "brian.otieno@email.com",    phone: "+254711001003", national_id: "23456783", unit: sunset_units[3] },
  { full_name: "Fatuma Ali",      email: "fatuma.ali@email.com",      phone: "+254711001004", national_id: "23456784", unit: sunset_units[4] },
  { full_name: "Kevin Kamau",     email: "kevin.kamau@email.com",     phone: "+254711001005", national_id: "23456785", unit: sunset_units[6] },
  { full_name: "Grace Njeri",     email: "grace.njeri@email.com",     phone: "+254711001006", national_id: "23456786", unit: sunset_units[7] },
  { full_name: "Peter Ochieng",   email: "peter.ochieng@email.com",   phone: "+254711001007", national_id: "23456787", unit: greenview_units[0] },
  { full_name: "Mercy Wanjiku",   email: "mercy.wanjiku@email.com",   phone: "+254711001008", national_id: "23456788", unit: greenview_units[1] },
  { full_name: "David Kipchoge",  email: "david.kipchoge@email.com",  phone: "+254711001009", national_id: "23456789", unit: greenview_units[2] },
  { full_name: "Lilian Auma",     email: "lilian.auma@email.com",     phone: "+254711001010", national_id: "23456790", unit: greenview_units[4] },
  { full_name: "Samuel Mutua",    email: "samuel.mutua@email.com",    phone: "+254711001011", national_id: "23456791", unit: greenview_units[5] },
  { full_name: "Zara Mohamed",    email: "zara.mohamed@email.com",    phone: "+254711001012", national_id: "23456792", unit: lakeside_units[0] },
  { full_name: "Hassan Salim",    email: "hassan.salim@email.com",    phone: "+254711001013", national_id: "23456793", unit: lakeside_units[1] },
  { full_name: "Caroline Chebet", email: "caroline.chebet@email.com", phone: "+254711001014", national_id: "23456794", unit: lakeside_units[2] },
]

tenants = tenants_data.map do |t|
  unit = t.delete(:unit)
  tenant = Tenant.create!(
    unit_id:     unit.id,
    full_name:   t[:full_name],
    email:       t[:email],
    phone:       t[:phone],
    national_id: t[:national_id],
    status:      "active",
    move_in_date:   Date.new(2024, 1, 1),
    lease_start:    Date.new(2024, 1, 1),
    lease_end:      Date.new(2024, 12, 31)
  )
  tenant
end

puts "Creating rent payments..."
if defined?(RentPayment) && RentPayment.column_names.any?
  rent_columns = RentPayment.column_names
  puts "RentPayment columns: #{rent_columns}"
  puts "Skipping rent payments - please check RentPayment columns and add manually"
else
  puts "RentPayment not found - skipping"
end

puts ""
puts "========================================="
puts "  Seed complete!"
puts "========================================="
puts "  Email:      demo@rentflow.com"
puts "  Password:   Demo1234!"
puts ""
puts "  Properties: #{Property.where(user_id: user.id).count}"
puts "  Units:      #{Unit.joins(:property).where(properties: { user_id: user.id }).count}"
puts "  Tenants:    #{Tenant.count}"
puts "========================================="

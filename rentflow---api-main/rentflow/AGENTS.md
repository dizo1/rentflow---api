# Development Commands

## Run Tests
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/rent_record_spec.rb
bundle exec rspec spec/controllers/api/v1/rent_records_controller_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

## Run Linter
```bash
bundle exec rubocop app/models/rent_record.rb app/controllers/api/v1/rent_records_controller.rb
bundle exec rubocop -a  # Auto-correct
```

## Run Migrations
```bash
bundle exec rails db:migrate
bundle exec rails db:migrate RAILS_ENV=test
```

## API Routes
```
GET    /api/v1/properties/:property_id/units/:unit_id/rent_records  -> index
POST   /api/v1/properties/:property_id/units/:unit_id/rent_records  -> create
GET    /api/v1/units/:unit_id/rent_records                           -> index
POST   /api/v1/units/:unit_id/rent_records                           -> create
GET    /api/v1/rent_records/:id                                      -> show
PUT    /api/v1/rent_records/:id                                      -> update
DELETE /api/v1/rent_records/:id                                      -> destroy

GET    /api/v1/properties/:property_id/units/:unit_id/maintenance_logs  -> index
POST   /api/v1/properties/:property_id/units/:unit_id/maintenance_logs  -> create
GET    /api/v1/units/:unit_id/maintenance_logs                        -> index
POST   /api/v1/units/:unit_id/maintenance_logs                        -> create
GET    /api/v1/maintenance_logs/:id                                   -> show
PUT    /api/v1/maintenance_logs/:id                                   -> update
DELETE /api/v1/maintenance_logs/:id                                   -> destroy
```
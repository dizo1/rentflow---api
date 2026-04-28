# Development Commands

## Run Tests
```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/models/tenant_spec.rb
bundle exec rspec spec/controllers/api/v1/tenants_controller_spec.rb
bundle exec rspec spec/models/rent_record_spec.rb
bundle exec rspec spec/controllers/api/v1/rent_records_controller_spec.rb
bundle exec rspec spec/models/maintenance_log_spec.rb
bundle exec rspec spec/controllers/api/v1/maintenance_logs_controller_spec.rb
bundle exec rspec spec/controllers/api/v1/maintenance_controller_spec.rb
bundle exec rspec spec/services/rent_record_generator_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

## Run Linter
```bash
bundle exec rubocop app/models/tenant.rb app/controllers/api/v1/tenants_controller.rb
bundle exec rubocop app/models/rent_record.rb app/controllers/api/v1/rent_records_controller.rb app/services/rent_record_generator.rb
bundle exec rubocop app/models/maintenance_log.rb app/controllers/api/v1/maintenance_logs_controller.rb app/controllers/api/v1/maintenance_controller.rb
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
POST    /api/v1/rent_records/:id/record_payment                      -> record_payment

GET    /api/v1/properties/:property_id/units/:unit_id/maintenance_logs  -> index
POST   /api/v1/properties/:property_id/units/:unit_id/maintenance_logs  -> create
GET    /api/v1/units/:unit_id/maintenance_logs                        -> index
POST   /api/v1/units/:unit_id/maintenance_logs                        -> create
GET    /api/v1/maintenance_logs/:id                                   -> show
PUT    /api/v1/maintenance_logs/:id                                   -> update
DELETE /api/v1/maintenance_logs/:id                                   -> destroy
PATCH   /api/v1/maintenance_logs/:id/resolve                          -> resolve

GET    /api/v1/tenants                                                -> index
POST   /api/v1/units/:unit_id/tenant                                  -> create
GET    /api/v1/units/:unit_id/tenant                                  -> show_by_unit
GET    /api/v1/tenants/:id                                            -> show
PUT    /api/v1/tenants/:id                                            -> update
DELETE /api/v1/tenants/:id                                            -> destroy

GET    /api/v1/maintenance/dashboard                                 -> maintenance_dashboard
GET    /api/v1/maintenance/properties/:property_id                    -> maintenance_index
PATCH  /api/v1/maintenance/:id/resolve                                -> maintenance_resolve
```
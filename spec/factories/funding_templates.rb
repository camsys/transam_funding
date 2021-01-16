FactoryBot.define do

  factory :funding_template do
    name { 'Test Funding Template' }
    description { 'Test Funding Template Description' }
    funding_source_id { 1 }
    contributor_id { 1 }
    owner_id { 1 }
    active { true }
  end

end

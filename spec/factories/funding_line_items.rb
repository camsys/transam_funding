FactoryBot.define do

  factory :funding_line_item do
    association :organization
    fy_year Date.today.year
    association :funding_source
    association :funding_line_item_type
    amount 1000
    spent 100
    pcnt_operating_assistance 100
  end
end

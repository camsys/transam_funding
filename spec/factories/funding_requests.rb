FactoryGirl.define do
  factory :funding_request do
    association :activity_line_item
    association :creator, :factory => :normal_user
    association :updator, :factory => :normal_user
    association :federal_funding_line_item, :factory => :funding_line_item
  end
end

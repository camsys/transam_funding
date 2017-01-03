FactoryGirl.define do

  factory :funding_plan do
    association :activity_line_item
    association :budget_amount
  end
end

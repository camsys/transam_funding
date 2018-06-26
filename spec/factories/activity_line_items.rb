FactoryBot.define do

  factory :activity_line_item do
    association :capital_project
    name 'Activity line item 1'
    fy_year 2014
    team_ali_code { FactoryBot.create(:replacement_ali_code, :parent => FactoryBot.create(:replacement_ali_code)) }
  end

end

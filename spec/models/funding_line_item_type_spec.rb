require 'rails_helper'

RSpec.describe FundingLineItemType, :type => :model do

  let(:test_type) { create(:funding_line_item_type) }

  it '.to_s' do
    expect(test_type.to_s).to eq(test_type.code)
  end
end

require 'rails_helper'

# currently not used model WIP
RSpec.describe FundingPlan, :skip, :type => :model do

  let(:test_plan) { create(:funding_plan) }

  describe 'associations' do
    it 'has an ali' do
      expect(test_plan).to belong_to(:activity_line_item)
    end
    it 'has a budget amount' do
      expect(test_plan).to belong_to(:budget_amount)
    end
  end
  describe 'validations' do
    it 'must have an ali' do
      test_plan.activity_line_item = nil
      expect(test_plan.valid?).to be false
    end
    it 'must have a budget amount' do
      test_plan.budget_amount = nil
      expect(test_plan.valid?).to be false
    end
    it 'must have an amount' do
      test_plan.amount = nil
      expect(test_plan.valid?).to be false
    end
  end

  it '#allowable_params' do
    expect(FundingPlan.allowable_params).to eq([
      :activity_line_item_id,
      :budget_amount_id,
      :amount
    ])
  end

  it '.to_s' do
    expect(test_plan.to_s).to eq(test_plan.name)
  end
  it '.name' do
    expect(test_plan.name).to eq("#{test_plan.budget_amount.funding_source.name} #{test_plan.amount}")
  end

  it '.federal_percentage' do

  end
  it '.federal_amount' do

  end
  it '.state_percentage' do

  end
  it '.state_amount' do

  end
  it '.local_percentage' do

  end
  it '.local_amount' do

  end

  it '.set_defaults' do
    expect(FundingPlan.new.amount).to eq(0)
  end
end

require 'rails_helper'

RSpec.describe FundingRequest, :skip, :type => :model do

  let(:test_request) { create(:funding_request) }

  describe 'associations' do
    it 'has federal funding line item' do
      expect(test_request).to belong_to(:federal_funding_line_item)
    end
    it 'has state funding line item' do
      expect(test_request).to belong_to(:state_funding_line_item)
    end
    it 'has ali' do
      expect(test_request).to belong_to(:activity_line_item)
    end
    it 'has creator' do
      expect(test_request).to belong_to(:creator)
    end
    it 'has updator' do
      expect(test_request).to belong_to(:updator)
    end
  end
  describe 'validations' do
    it 'must have an ali' do
      test_request.activity_line_item = nil
      expect(test_request.valid?).to be false
    end
    describe 'federal amount' do
      it 'must be an integer' do
        test_request.federal_amount = 2.5
        expect(test_request.valid?).to be false
      end
      it 'cannot be negative' do
        test_request.federal_amount = -1
        expect(test_request.valid?).to be false
      end
    end
    describe 'state amount' do
      it 'must be an integer' do
        test_request.state_amount = 2.5
        expect(test_request.valid?).to be false
      end
      it 'cannot be negative' do
        test_request.state_amount = -1
        expect(test_request.valid?).to be false
      end
    end
    describe 'local amount' do
      it 'must be an integer' do
        test_request.local_amount = 2.5
        expect(test_request.valid?).to be false
      end
      it 'cannot be negative' do
        test_request.local_amount = -1
        expect(test_request.valid?).to be false
      end
    end
    it 'must have a creator' do
      test_request.creator = nil
      expect(test_request.valid?).to be false
    end
    it 'must have an updator' do
      test_request.updator = nil
      expect(test_request.valid?).to be false
    end
  end

  it '#allowable_params' do
    expect(FundingRequest.allowable_params).to eq([
      :object_key,
      :federal_funding_line_item_id,
      :state_funding_line_item_id,
      :activity_line_item_id,
      :federal_amount,
      :state_amount,
      :local_amount
    ])
  end

  describe 'percentages' do
    before(:each) do
      test_request.update!(:federal_amount => 100, :state_amount => 60, :local_amount => 40)
    end
    it '.total_amount' do
      expect(test_request.total_amount).to eq(200)
    end
    it '.federal_percentage' do
      expect(test_request.federal_percentage).to eq(50)
    end
    it '.state_percentage' do
      expect(test_request.state_percentage).to eq(30)
    end
    it '.local_percentage' do
      expect(test_request.local_percentage).to eq(20)
    end
  end

  it '.name' do
    expect(test_request.name).to eq(test_request.federal_funding_line_item.funding_source.name)
  end

  it '.set_defaults' do
    expect(FundingRequest.new.federal_amount).to eq(0)
    expect(FundingRequest.new.state_amount).to eq(0)
    expect(FundingRequest.new.local_amount).to eq(0)
  end
end

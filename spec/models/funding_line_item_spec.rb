require 'rails_helper'

RSpec.describe FundingLineItem, :skip, :type => :model do

  let(:test_item) { create(:funding_line_item) }

  describe 'associations' do
    it 'has an org' do
      expect(test_item).to belong_to(:organization)
    end
    it 'has a funding source' do
      expect(test_item).to belong_to(:funding_source)
    end
    it 'has a type' do
      expect(test_item).to belong_to(:funding_line_item_type)
    end
    it 'has a creator' do
      expect(test_item).to belong_to(:creator)
    end
    it 'has an updator' do
      expect(test_item).to belong_to(:updator)
    end
    it 'has documents' do
      expect(test_item).to have_many(:documents)
    end
    it 'has comments' do
      expect(test_item).to have_many(:comments)
    end
  end

  describe 'validations' do
    it 'must have an org' do
      test_item.organization = nil
      expect(test_item.valid?).to be false
    end
    it 'must have a FY' do
      test_item.fy_year = nil
      expect(test_item.valid?).to be false
    end
    it 'must have a funding source' do
      test_item.funding_source = nil
      expect(test_item.valid?).to be false
    end
    it 'must have a type' do
      test_item.funding_line_item_type = nil
      expect(test_item.valid?).to be false
    end
    describe 'spent amount' do
      it 'must exist' do
        test_item.spent = nil
        expect(test_item.valid?).to be false
      end
      it 'must be an integer' do
        test_item.spent = 2.5
        expect(test_item.valid?).to be false
      end
      it 'cannot be negative' do
        test_item.spent = -1
        expect(test_item.valid?).to be false
      end
    end
    describe 'operating assistance percentage' do
      it 'must exist' do
        test_item.pcnt_operating_assistance = nil
        expect(test_item.valid?).to be false
      end
      it 'must be an integer' do
        test_item.pcnt_operating_assistance = 2.5
        expect(test_item.valid?).to be false
      end
      it 'must be a percentage' do
        test_item.pcnt_operating_assistance = -1
        expect(test_item.valid?).to be false
        test_item.pcnt_operating_assistance = 101
        expect(test_item.valid?).to be false
      end
    end
  end

  it '#allowable_params' do
    expect(FundingLineItem.allowable_params).to eq([
      :organization_id,
      :fy_year,
      :funding_source_id,
      :funding_line_item_type_id,
      :project_number,
      :awarded,
      :amount,
      :spent,
      :pcnt_operating_assistance,
      :active
    ])
  end

  it '.cash_flow' do
    test_request = create(:funding_request, :federal_funding_line_item => test_item, :federal_amount => 500)

    test_request.activity_line_item.capital_project.update!(:fy_year => test_item.fy_year)

    expect(test_item.cash_flow).to include(["FY #{Date.today.year-2000}-#{Date.today.year-2000+1}", 1000, 100, 500, 400])
  end
  it '.funding_requests' do
    test_request = create(:funding_request, :federal_funding_line_item => test_item)

    expect(test_item.funding_requests).to include(test_request)
  end
  it '.committed' do
    test_request = create(:funding_request, :federal_funding_line_item => test_item, :federal_amount => 500)

    expect(test_item.committed).to eq(test_request.federal_amount)
  end
  it '.balance' do
    test_request = create(:funding_request, :federal_funding_line_item => test_item, :federal_amount => 500)

    expect(test_item.balance).to eq(1000-100-500)
  end
  describe '.available' do
    it 'existing funds' do
      test_request = create(:funding_request, :federal_funding_line_item => test_item, :federal_amount => 500)

      expect(test_item.available).to eq(1000-100-500)
    end
    it 'no funds' do
      test_request = create(:funding_request, :federal_funding_line_item => test_item, :federal_amount => 1500)

      expect(test_item.available).to eq(0)
    end
  end
  it '.non_operating_funds' do
    expect(test_item.non_operating_funds).to eq(0)
  end
  it '.operating_funds' do
    expect(test_item.operating_funds).to eq(test_item.amount)
    expect(test_item.operating_funds).to eq(1000)
  end
  describe '.federal?' do
    it 'no funding source' do
      test_item.funding_source = nil

      expect(test_item.federal?).to be false
    end
    it 'funding source' do
      expect(test_item.federal?).to eq(test_item.funding_source.federal?)
      expect(test_item.federal?).to be true
    end
  end
  describe '.fiscal_year' do
    before(:each) do
      test_item.fy_year = 2002
    end
    it 'no year' do
      expect(test_item.fiscal_year).to eq('FY 02-03')
    end
    it 'given year' do
      expect(test_item.fiscal_year(2009)).to eq('FY 09-10')
    end
  end
  it '.to_s' do
    expect(test_item.to_s).to eq(test_item.name)
  end
  describe '.name' do
    it 'no project number' do
      expect(test_item.name).to eq('N/A')
    end
    it 'otherwise' do
      test_item.project_number = 'prj_num123'
      expect(test_item.name).to eq(test_item.project_number)
    end
  end
  describe '.details' do
    it 'no project number' do
      expect(test_item.details).to eq("#{test_item.funding_source} #{test_item.fiscal_year} ($#{test_item.available})")
    end
    it 'otherwise' do
      test_item.project_number = 'prj_num123'
      eq("#{test_item.funding_source} #{test_item.fiscal_year}: #{test_item.project_number} ($#{test_item.available})")
    end
  end

  it '.set_defaults' do
    test_item = FundingLineItem.new

    expect(test_item.amount).to eq(0)
    expect(test_item.pcnt_operating_assistance).to eq(0)
    expect(test_item.fy_year).to eq(Date.today.month > 6 ? Date.today.year + 1 : Date.today.year)
  end
end

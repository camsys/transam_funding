require 'rails_helper'

RSpec.describe FundingTemplate, type: :model do

    let(:funding_template) { create(:funding_template) }
    let(:user) { create(:normal_user) }

    it { should respond_to :creator_org }

    it "responds correctly to creator org" do
      # The funding template does not have a user, it will return nil for creator org 
      expect(funding_template.creator_org).to eq(nil)

      funding_template.creator = user
      expect(funding_template.creator_org).to eq(user.organization.short_name)
    end

    it 'defaults to not recurring' do
      expect(funding_template.recurring).to eq(false)
    end

    it 'can set recurring' do
      test_template = create(:funding_template, recurring: true)
      expect(test_template.recurring).to eq(true)
    end

end
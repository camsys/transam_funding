require 'rails_helper'

RSpec.describe FundingTemplate, type: :model do

    let(:funding_template) { create(:funding_template) }
    let(:user) { create(:normal_user) }

    it { should respond_to :creator_org }

    describe 'associations' do
      it "responds correctly to creator org" do
        # The funding template does not have a user, it will return nil for creator org
        expect(funding_template.creator_org).to eq(nil)

        funding_template.creator = user
        expect(funding_template.creator_org).to eq(user.organization.short_name)
      end

      # contributor/owner and respective orgs
      it 'responds to contributor' do
        expect(FundingTemplate.new).to belong_to(:contributor)
      end
      it 'contributor is type of FundingOrganizationType' do
        expect { FundingTemplate.new.contributor = FundingSourceType.first}.to raise_error
        expect { FundingTemplate.new.contributor = FundingOrganizationType.first}.to_not raise_error
      end
      it 'responds to owner' do
        expect(FundingTemplate.new).to belong_to(:owner)
      end
      it 'owner is type of FundingOrganizationType' do
        expect { FundingTemplate.new.owner = FundingSourceType.first}.to raise_error
        expect { FundingTemplate.new.owner = FundingOrganizationType.first}.to_not raise_error
      end
      it 'responds to contributor orgs' do
        expect(FundingTemplate.new).to have_and_belong_to_many(:contributor_organizations)
      end
      it 'responds to owner orgs' do
        expect(FundingTemplate.new).to have_and_belong_to_many(:organizations)
      end
    end

    describe 'recurring field' do
      it 'defaults to not recurring' do
        expect(funding_template.recurring).to eq(false)
      end

      it 'can set recurring' do
        test_template = create(:funding_template, recurring: true)
        expect(test_template.recurring).to eq(true)
      end
    end

    describe 'active field' do
      it 'responds to active' do
        expect(funding_template.respond_to? :active).to eq(true)
      end
      it 'defaults to true' do
        expect(funding_template.active).to eq(true)
      end
      it 'can set active' do
        test_template = create(:funding_template, active: false)
        expect(test_template.active).to eq(false)
      end
    end


end
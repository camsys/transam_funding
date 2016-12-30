require 'rails_helper'

describe "assets/_accounting_detail_tabs_content.html.haml", :type => :view do

  class TestOrg < Organization
    def get_policy
      return Policy.find_by_organization_id(self.id)
    end
  end

  it 'no expenditures' do
    test_user = create(:admin)
    allow(controller).to receive(:current_user).and_return(test_user)
    allow(controller).to receive(:current_ability).and_return(Ability.new(test_user))

    org = create(:organization)
    asset_subtype = AssetSubtype.first
    policy = create(:policy, :organization => org)
    create(:policy_asset_type_rule, :policy => policy, :asset_type => asset_subtype.asset_type)
    create(:policy_asset_subtype_rule, :policy => policy, :asset_subtype => asset_subtype)
    test_asset = create(:buslike_asset, :book_value => 7890, :organization => org, :asset_type => asset_subtype.asset_type, :asset_subtype => asset_subtype)

    assign(:asset, test_asset)
    create(:policy, :organization => test_asset.organization)
    assign(:expenditure, Expenditure.new)
    assign(:organization, test_asset.organization)
    render

    expect(rendered).to have_content('There are no CapEx associated with this asset.')
  end
end

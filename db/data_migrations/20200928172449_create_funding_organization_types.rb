class CreateFundingOrganizationTypes < ActiveRecord::DataMigration
  def up
    funding_organization_types = [
        {name: 'Grantor', code: 'grantor', active: true},
        {name: 'Transit Agency', code: 'agency', active: true}
    ]

    funding_organization_types.each do |type|
      FundingOrganizationType.create!(type)
    end
  end
end
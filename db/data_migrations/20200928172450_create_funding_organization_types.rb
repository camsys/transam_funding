class CreateFundingOrganizationTypes < ActiveRecord::DataMigration
  def up
    funding_organization_types = [
        {name: 'Grantor', code: 'grantor', active: true},
        {name: 'Transit Agency', code: 'agency', active: true}
    ]

    funding_organization_types.each do |type|
      FundingOrganizationType.find_or_create_by(type)
    end

    FundingTemplate.all.each do |template|
      if template.contributor_id.present?
        if template.contributor_id == FundingSourceType.find_by(name: 'State').id
          template.contributor = FundingOrganizationType.find_by(code: 'grantor')
        else
          template.contributor = FundingOrganizationType.find_by(code: 'agency')
        end
      end

      if template.owner_id.present?
        if template.owner_id == FundingSourceType.find_by(name: 'State').id
          template.owner = FundingOrganizationType.find_by(code: 'grantor')
        else
          template.owner = FundingOrganizationType.find_by(code: 'agency')
        end
      end
    end
  end
end
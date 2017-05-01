module Abilities
  class AuthorizedAccountingAbility
    include CanCan::Ability

    def initialize(user)

      #-------------------------------------------------------------------------
      # Funding
      #-------------------------------------------------------------------------

      cannot :read, FundingTemplate
      cannot :read, FundingBucket do |b|
        !(user.organization_ids.include? b.owner_id)
      end
      can :my_funds, FundingBucket

      can [:create, :read, :update], FundingRequest
      can :destroy, FundingRequest do |fr|
        grantor_org_id = Organization.find_by(organization_type: OrganizationType.find_by(class_name: 'Grantor')).id
        (
          (fr.creator.organization_ids.include?(grantor_org_id) && user.organization_ids.include?(grantor_org_id)) ||
          (!fr.creator.organization_ids.include?(grantor_org_id) && user.organization_ids.include?(fr.activity_line_item.organization.id))
        )
      end


    end
  end
end
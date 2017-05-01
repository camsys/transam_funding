module Abilities
  class ManagerAccountingAbility
    include CanCan::Ability

    def initialize(user)


      #-------------------------------------------------------------------------
      # Funding
      #-------------------------------------------------------------------------

      can :read, FundingTemplate
      can [:read, :my_funds], FundingBucket

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
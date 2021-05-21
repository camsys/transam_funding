module Abilities
  class TransitManagerFundingAbility
    include CanCan::Ability

    def initialize(user, organization_ids=[])
      if organization_ids.empty?
        organization_ids = user.organization_ids
      end

      can :manage, FundingBucket do |b|
        (organization_ids.include? b.contributor_id)
      end
      if Rails.application.config.try(:uses_bonds)
        can :manage, BondRequest do |b|
          organization_ids.include? b.organization_id
        end
        cannot :update_status, BondRequest
      end

      can [:add_funding_request], ActivityLineItem do |ali|
        !ali.notional? && ali.milestones.find_by(milestone_type: MilestoneType.find_by(name: "Contract Complete")).try(:milestone_date).present?
      end
      can [:create, :update], FundingRequest
      can :destroy, FundingRequest do |fr|
        grantor_org_id = Organization.find_by(organization_type: OrganizationType.find_by(class_name: 'Grantor')).id
        (
        (fr.creator.organization_ids.include?(grantor_org_id) && organization_ids.include?(grantor_org_id)) ||
            (!fr.creator.organization_ids.include?(grantor_org_id) && organization_ids.include?(fr.activity_line_item.organization.id))
        )
      end
      
    end
  end
end

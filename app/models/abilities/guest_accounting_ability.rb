module Abilities
  class GuestAccountingAbility
    include CanCan::Ability

    def initialize(user)

      #-------------------------------------------------------------------------
      # Funding
      #-------------------------------------------------------------------------

      unless user.organization.organization_type == OrganizationType.find_by(class_name: 'Grantor')
        cannot :read, FundingTemplate
        cannot :read, FundingBucket do |b|
          !(user.organization_ids.include? b.owner_id)
        end
        cannot :read, FundingRequest
      end
      can :my_funds, FundingBucket
    end
  end
end
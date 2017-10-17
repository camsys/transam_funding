module Abilities
  class AuthorizedFundingAbility
    include CanCan::Ability

    def initialize(user, organization_ids=[])

      if organization_ids.empty?
        organization_ids = user.organization_ids
      end

      #-------------------------------------------------------------------------
      # Funding
      #-------------------------------------------------------------------------

      cannot :read, FundingTemplate
      cannot :read, FundingBucket do |b|
        !(organization_ids.include? b.owner_id)
      end
      can :my_funds, FundingBucket


    end
  end
end
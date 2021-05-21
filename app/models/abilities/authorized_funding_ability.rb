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

      cannot :read, FundingBucket do |b|
        !(organization_ids.include? b.owner_id)
      end

    end
  end
end

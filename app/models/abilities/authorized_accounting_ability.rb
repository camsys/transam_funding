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
      can :delete, FundingRequest do |fr|
        user.organization_ids.include? b.creator.id
      end


    end
  end
end
module Abilities
  class ManagerFundingAbility
    include CanCan::Ability

    def initialize(user)


      #-------------------------------------------------------------------------
      # Funding
      #-------------------------------------------------------------------------

      can :read, FundingTemplate
      can [:read, :my_funds], FundingBucket
      can :manage, FundingRequest

      can :manage, BondRequest
      cannot :update_status, BondRequest

    end
  end
end
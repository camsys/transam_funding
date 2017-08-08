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

    end
  end
end
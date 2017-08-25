module Abilities
  class SuperManagerFundingAbility
    include CanCan::Ability

    def initialize(user)

      can :manage, FundingTemplate
      can :manage, FundingBucket

      can :manage, BondRequest
    end
  end
end
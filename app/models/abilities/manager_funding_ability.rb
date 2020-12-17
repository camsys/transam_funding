module Abilities
  class ManagerFundingAbility
    include CanCan::Ability

    def initialize(user)


      #-------------------------------------------------------------------------
      # Funding
      #-------------------------------------------------------------------------

      can :read, FundingTemplate
      can [:read, :my_funds], FundingBucket

      if Rails.application.config.try(:uses_bonds)
        can :manage, BondRequest
        cannot :update_status, BondRequest
      end

    end
  end
end
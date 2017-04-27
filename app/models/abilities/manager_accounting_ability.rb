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
      can :delete, FundingRequest do |fr|
        user.organization_ids.include? b.creator.id
      end

    end
  end
end
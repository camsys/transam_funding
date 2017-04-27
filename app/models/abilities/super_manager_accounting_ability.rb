module Abilities
  class SuperManagerAccountingAbility
    include CanCan::Ability

    def initialize(user)

      can :manage, FundingTemplate
      can :manage, FundingBucket

      can [:create, :read, :update], FundingRequest
      can :delete, FundingRequest do |fr|
        user.organization_ids.include? b.creator.id
      end

    end
  end
end
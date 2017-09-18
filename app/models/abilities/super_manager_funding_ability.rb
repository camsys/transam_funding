module Abilities
  class SuperManagerFundingAbility
    include CanCan::Ability

    def initialize(user)

      can :manage, FundingTemplate
      can :manage, FundingBucket

      can :manage, BondRequest

      can [:add_funding_request], ActivityLineItem do |ali|
        ali.milestones.find_by(milestone_type: MilestoneType.find_by(name: "Contract Completed")).try(:milestone_date).present?
      end

      can :manage, FundingRequest
    end
  end
end
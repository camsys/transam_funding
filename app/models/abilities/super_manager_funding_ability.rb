module Abilities
  class SuperManagerFundingAbility
    include CanCan::Ability

    def initialize(user)

      can :manage, FundingTemplate
      can :manage, FundingBucket

      if Rails.application.config.try(:uses_bonds)
        can :manage, BondRequest
      end

      can [:add_funding_request], ActivityLineItem do |ali|
        !ali.notional? && ali.milestones.find_by(milestone_type: MilestoneType.find_by(name: "Contract Complete")).try(:milestone_date).present?
      end

      can :manage, FundingRequest
    end
  end
end
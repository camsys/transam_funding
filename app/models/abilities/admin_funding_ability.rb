module Abilities
  class AdminFundingAbility
    include CanCan::Ability

    def initialize(user)

      can [:add_funding_request], ActivityLineItem do |ali|
        !ali.notional? && ali.milestones.find_by(milestone_type: MilestoneType.find_by(name: "Contract Completed")).try(:milestone_date).present?
      end


    end
  end
end
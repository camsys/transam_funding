module Abilities
  class TransitManagerFundingAbility
    include CanCan::Ability

    def initialize(user)

      can :new_bucket_app, FundingBucket
      can [:edit_bucket_app, :destroy], FundingBucket do |b|
        (user.organization_ids.include? b.owner_id) && b.is_bucket_app?
      end

      can :manage, BondRequest do |b|
        user.organization_ids.include? b.organization_id
      end
      cannot :update_status, BondRequest
      
    end
  end
end
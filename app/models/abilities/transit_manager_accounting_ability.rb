module Abilities
  class TransitManagerAccountingAbility
    include CanCan::Ability

    def initialize(user)

      can :new_bucket_app, FundingBucket
      can [:edit_bucket_app, :destroy], FundingBucket do |b|
        (user.organization_ids.include? b.owner_id) && b.is_bucket_app?
      end

      can [:create, :read, :update], FundingRequest
      can :delete, FundingRequest do |fr|
        user.organization_ids.include? b.creator.id
      end
      
    end
  end
end
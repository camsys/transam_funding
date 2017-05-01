module Abilities
  class TransitManagerAccountingAbility
    include CanCan::Ability

    def initialize(user)

      can :new_bucket_app, FundingBucket
      can [:edit_bucket_app, :destroy], FundingBucket do |b|
        (user.organization_ids.include? b.owner_id) && b.is_bucket_app?
      end

      can [:create, :read, :update], FundingRequest
      can :destroy, FundingRequest do |fr|
        grantor_org_id = Organization.type_of?(Grantor).id
        (
        (fr.creator.organization_ids.include?(grantor_org_id) && user.organization_ids.include?(grantor_org_id)) ||
            (!fr.creator.organization_ids.include?(grantor_org_id) && user.organization_ids.include?(fr.activity_line_item.organization.id))
        )
      end
      
    end
  end
end
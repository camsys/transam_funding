class FundingCompleteConstrainedCapitalPlanAction < BaseCapitalPlanAction

  def system_action?
    true
  end

  def complete
    capital_plan = @capital_plan_action.capital_plan
    alis = ActivityLineItem.joins(:capital_project).where(capital_projects: {fy_year: capital_plan.fy_year, organization_id: capital_plan.organization_id})

    total_funds = FundingRequest.where(activity_line_item_id: alis.ids).sum('federal_amount + state_amount + local_amount')
    total_ali_cost = alis.sum(ActivityLineItem::COST_SUM_SQL_CLAUSE)
    pcnt_funded = total_ali_cost > 0 ?  (total_funds * 100.0 / total_ali_cost).to_i : 100


    overcommitted_buckets = FundingBucket.where(id: FundingRequest.joins(activity_line_item: :capital_project).where('capital_projects.organization_id = ? AND capital_projects.fy_year = ?', capital_plan.organization_id, capital_plan.fy_year).pluck(:federal_funding_line_item_id, :state_funding_line_item_id, :local_funding_line_item_id).flatten.uniq).where('budget_committed > budget_amount')
    if overcommitted_buckets.count > 0
      if @user.organization.organization_type.class_name == 'Grantor'
        url = Rails.application.routes.url_helpers.funding_buckets_url(funds_filter: 'funds_overcommitted')
        notes = "<a href='#{url}' style='color:red;'>#{pcnt_funded}%</a>"
      elsif overcommitted_buckets.where(owner_id: capital_plan.organization_id).count > 0
        url = Rails.application.routes.url_helpers.my_funds_funding_buckets_url(funds_filter: 'funds_overcommitted')
        notes = "<a href='#{url}' style='color:red;'>#{pcnt_funded}%</a>"
      else
        notes = "<span style='color:red;'>#{pcnt_funded}%</span>"
      end
    else
      notes = "#{pcnt_funded}%"
    end

    @capital_plan_action.update(completed_pcnt: pcnt_funded, notes: notes)

  end

  def post_process
    overcommitted_buckets_count = FundingBucket.where(id: FundingRequest.joins(activity_line_item: :capital_project).where('capital_projects.organization_id = ?', @capital_plan_action.capital_plan.organization_id).pluck(:federal_funding_line_item_id, :state_funding_line_item_id, :local_funding_line_item_id).flatten.uniq).where('budget_committed > budget_amount').count
    if @capital_plan_action.completed_pcnt == 100 && overcommitted_buckets_count == 0
      super
    else
      undo_post_process
    end
  end

end
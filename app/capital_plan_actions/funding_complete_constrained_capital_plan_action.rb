class FundingCompleteConstrainedCapitalPlanAction < BaseCapitalPlanAction

  def system_action?
    true
  end

  def complete
    capital_plan = @capital_plan_action.capital_plan
    alis = ActivityLineItem.joins(:capital_project).where(capital_projects: {fy_year: capital_plan.fy_year, organization_id: capital_plan.organization_id})
    ali_count = alis.count
    funded_ali_count = 0
    alis.each do |ali|
      funded_ali_count += 1 if ali.pcnt_funded == 100
    end

    pcnt_funded = ali_count > 0 ? (funded_ali_count * 100.0 / ali_count).to_i : 100

    if @user.organization.organization_type.class_name == 'Grantor'
      url = Rails.application.routes.url_helpers.funding_buckets_url(funds_filter: 'funds_overcommitted')
    else
      url = Rails.application.routes.url_helpers.my_funds_funding_buckets_url(funds_filter: 'funds_overcommitted')
    end

    @capital_plan_action.update(completed_pcnt: pcnt_funded, notes: "<a href='#{url}' style='color:red;'>#{total_pcnt_passed}%</a>")

  end

  def post_process
    if @capital_plan_action.completed_pcnt == 100
      super
    end
  end

end
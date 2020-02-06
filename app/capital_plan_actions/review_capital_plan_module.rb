class ReviewCapitalPlanModule < BaseCapitalPlanModule

  include TransamFormatHelper

  def complete
    plan = @capital_plan_module.capital_plan

    # soft delete all capital projects and ALIs
    projs = CapitalProject.where(organization_id: plan.organization_id, fy_year: plan.fy_year)
    alis = ActivityLineItem.where(capital_project_id: projs.ids)
    alis.update_all(active: false)
    projs.update_all(active: false)

    alis.each do |ali|
      # mark all assets as under replacement
      ali.assets.each do |asset|
        ReplacementStatusUpdateEvent.create(transam_asset: asset, replacement_year: plan.fy_year, replacement_status_type_id: ReplacementStatusType.find_by(name: 'Underway').id, comments: "The #{format_as_fiscal_year(plan.fy_year)} capital plan includes the replacement of this asset.")

        # use try as new profiles don't have update_methods
        asset.try(:update_replacement_status)
        asset.try(:update_sogr)
      end

      # update bucket budget amounts and committed amounts, soft delete if bucket used up
      ali.funding_requests.each do |request|
        fed_bucket = request.federal_funding_line_item
        if fed_bucket
          fed_bucket.budget_amount = fed_bucket.budget_amount-request.federal_amount
          fed_bucket.budget_committed = fed_bucket.budget_committed-request.federal_amount
          if fed_bucket.budget_amount == 0
            fed_bucket.active = false
          end
          fed_bucket.save
        end

        state_bucket = request.state_funding_line_item
        if state_bucket
          state_bucket.budget_amount = state_bucket.budget_amount-request.state_amount
          state_bucket.budget_committed = state_bucket.budget_committed-request.state_amount
          if state_bucket.budget_amount == 0
            state_bucket.active = false
          end
          state_bucket.save
        end

        local_bucket = request.local_funding_line_item
        if local_bucket
          local_bucket.budget_amount = local_bucket.budget_amount-request.local_amount
          local_bucket.budget_committed = local_bucket.budget_committed-request.local_amount
          if local_bucket.budget_amount == 0
            local_bucket.active = false
          end
          local_bucket.save
        end

      end
    end

  end
end
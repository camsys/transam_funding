class NeedsFundingReport < AbstractReport

  include FiscalYear

  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_data(organization_id_list, params)


    fiscal_years = get_fiscal_years

        # Assumption: data values have already been divided by 10^6 when returned.
    needs = ActivityLineItem.unscoped.order("activity_line_items.fy_year").group("activity_line_items.fy_year").sum(ActivityLineItem::COST_SUM_SQL_CLAUSE)

    total_funds = FundingBucket.where('fy_year > ?', current_planning_year_year).order(:fy_year).group(:fy_year).sum(:budget_amount)
    fed_funds = FundingBucket.federal.where('fy_year > ?', current_planning_year_year).order(:fy_year).group(:fy_year).sum(:budget_amount)
    state_funds = FundingBucket.state.where('fy_year > ?', current_planning_year_year).order(:fy_year).group(:fy_year).sum(:budget_amount)
    local_funds = FundingBucket.local.where('fy_year > ?', current_planning_year_year).order(:fy_year).group(:fy_year).sum(:budget_amount)

    total_funds[current_planning_year_year] = FundingBucket.current(current_planning_year_year).sum(:budget_amount)
    fed_funds[current_planning_year_year] = FundingBucket.federal.current(current_planning_year_year).sum(:budget_amount)
    state_funds[current_planning_year_year] = FundingBucket.state.current(current_planning_year_year).sum(:budget_amount)
    local_funds[current_planning_year_year] = FundingBucket.local.current(current_planning_year_year).sum(:budget_amount)

    labels = [get_fiscal_year_label, 'Total Needs', 'Total Federal Funds', 'Total State Funds',
              'Total Local Funds', 'Balance/(Shortfall)']
    formats = [nil, :currency, :currency, :currency, :currency, :currency]

    data = []
    fiscal_years.each do |fy|
      fy_need = (needs[fy[1]] || 0)
      data << [fy[0], fy_need, fed_funds[fy[1]] || 0, state_funds[fy[1]] || 0, local_funds[fy[1]] || 0, (total_funds[fy[1]] || 0) - fy_need]
    end

    return {labels: labels, data: data, formats: formats}
  end
end
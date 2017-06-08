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
    fed_funds = FundingBucket.federal.where('fy_year > ?', current_planning_year_year).order(:fy_year).group(:fy_year).sum('budget_amount/1000000')
    state_funds = FundingBucket.state.where('fy_year > ?', current_planning_year_year).order(:fy_year).group(:fy_year).sum('budget_amount/1000000')
    local_funds = FundingBucket.local.where('fy_year > ?', current_planning_year_year).order(:fy_year).group(:fy_year).sum('budget_amount/1000000')

    total_funds[current_planning_year_year] = FundingBucket.current(current_planning_year_year).sum(:budget_amount)
    fed_funds[current_planning_year_year] = (FundingBucket.federal.current(current_planning_year_year).sum(:budget_amount)/1000000.0).round(2)
    state_funds[current_planning_year_year] = (FundingBucket.state.current(current_planning_year_year).sum(:budget_amount)/1000000.0).round(2)
    local_funds[current_planning_year_year] = (FundingBucket.local.current(current_planning_year_year).sum(:budget_amount)/1000000.0).round(2)

    labels = ['Fiscal Year', 'Total Needs ($M)', 'Total Federal Funds ($M)', 'Total State Funds ($M)',
              'Total Local Funds ($M)', 'Balance/(Shortfall) ($M)']
    formats = [nil, :currencyM, :currencyM, :currencyM, :currencyM, :currencyM]

    data = []
    fiscal_years.each do |fy|
      fy_need = (needs[fy[1]] || 0)
      data << [fy[0], (fy_need/ 1000000.0).round(2), fed_funds[fy[1]] || 0, state_funds[fy[1]] || 0, local_funds[fy[1]] || 0, (((total_funds[fy[1]] || 0) - fy_need)/1000000.0).round(2)]
    end

    return {labels: labels, data: data, formats: formats}
  end
end
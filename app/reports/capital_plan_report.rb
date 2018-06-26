class CapitalPlanReport < AbstractReport

  include FiscalYear
  
  KEY_INDEX = 2
  DETAIL_LABELS = ['NAME', FiscalYearHelper.get_fy_label, 'Sub Category', '# Assets', 'Cost', 'Federal', 'State', 'Local']
  DETAIL_FORMATS = [:string, :fiscal_year, :string, :integer, :currency, :currency, :currency, :currency]
  
  def initialize(attributes = {})
    super(attributes)
  end    
  
  def self.get_detail_data(organization_id_list, params)
    query = ActivityLineItem.joins(:capital_project).includes(:team_ali_code)
            .where(capital_projects: {object_key: params[:key]})

    data = query.pluck(:id, :name, :fy_year, 'team_ali_codes.code').to_a
    query = query.group('activity_line_items.id')
    asset_counts = query.joins(:assets).count(:asset_id)
    costs = query.sum(ActivityLineItem::COST_SUM_SQL_CLAUSE)
    # eager_load implicitly performs left join
    query = query.eager_load(:funding_requests)
    federal = query.sum('funding_requests.federal_amount')
    state = query.sum('funding_requests.state_amount')
    local = query.sum('funding_requests.local_amount')

    data.each do |row|
      id = row[0]
      row << asset_counts[id]
      row << costs[id]
      row << federal[id]
      row << state[id]
      row << local[id]
      row.shift                 # remove initial id
    end

    {labels: DETAIL_LABELS, data: data, formats: DETAIL_FORMATS}
  end
  
  def get_actions
    @actions = [
      {
        type: :select,
        where: :start_fy_year,
        values: get_fiscal_years,
        label: 'From'
      },
      {
        type: :select,
        where: :end_fy_year,
        values: get_fiscal_years,
        label: 'To'
      }
    ]
  end
  
  def get_data(organization_id_list, params)
    labels = [FiscalYearHelper.get_fy_label, 'Project', 'object_key', 'Title', 'Scope', '#&nbsp;ALIs', 'Cost', 'Fed&nbsp;$', 'State&nbsp;$', 'Local&nbsp;$']
    formats = [:fiscal_year, :string, :hidden, :string, :string, :integer, :currency, :currency, :currency, :currency]
    
    # Order by org name, then by FY
    query = CapitalProject.where(organization_id: organization_id_list).joins(:organization).order('organizations.name', :fy_year)

    # Add clauses based on params
    conditions = []
    values = []

    value = params[:start_fy_year] || current_planning_year_year
    conditions << 'capital_projects.fy_year >= ?'
    start_year = value.to_i 
    values << start_year
    
    value = params[:end_fy_year] || current_planning_year_year
    conditions << 'capital_projects.fy_year <= ?'
    end_year = value.to_i 
    values << end_year

    # Validation
    if end_year < start_year
      return "To Year cannot be before From Year."
    end
    
    query = query.where(conditions.join(' AND '), *values).eager_load(:activity_line_items, :funding_requests)
    
    data = []
    org_data = []
    current_org = nil
    current_fy = nil
    total_ali_count = total_cost = total_federal_funds = total_state_funds = total_local_funds = 0
    
    query.each do |cp|
      row = [
        cp.fy_year,
        cp.project_number,
        cp.object_key,
        cp.title,
        cp.team_ali_code.scope,
        cp.activity_line_items.count,
        cp.total_cost,
        cp.federal_funds,
        cp.state_funds,
        cp.local_funds
      ]
      if current_org != cp.organization
        if current_org
          org_data << [nil, "Totals for #{fiscal_year(current_fy)}", nil, nil, nil, total_ali_count,
                       total_cost, total_federal_funds, total_state_funds, total_local_funds]
          data << [current_org.name, org_data]
        end
        current_fy = cp.fy_year
        total_ali_count = cp.activity_line_items.count
        total_cost = cp.total_cost
        total_federal_funds = cp.federal_funds
        total_state_funds = cp.state_funds
        total_local_funds = cp.local_funds

        org_data = [row]
        current_org = cp.organization
      else
        if current_fy == cp.fy_year
          total_ali_count += cp.activity_line_items.count
          total_cost += cp.total_cost
          total_federal_funds += cp.federal_funds
          total_state_funds += cp.state_funds
          total_local_funds += cp.local_funds
        else
          if current_fy
            org_data << [nil, "Totals for #{fiscal_year(current_fy)}", nil, nil, nil, total_ali_count,
                         total_cost, total_federal_funds, total_state_funds, total_local_funds]
          end
          current_fy = cp.fy_year
          total_ali_count = cp.activity_line_items.count
          total_cost = cp.total_cost
          total_federal_funds = cp.federal_funds
          total_state_funds = cp.state_funds
          total_local_funds = cp.local_funds
        end
        org_data << row
      end
    end
    org_data << [nil, "Totals for #{fiscal_year(current_fy)}", nil, nil, nil, total_ali_count,
                 total_cost, total_federal_funds, total_state_funds, total_local_funds]
    data << [current_org.name, org_data]
    
    return {labels: labels, data: data, formats: formats}
  end

  def get_key(row)
    row[KEY_INDEX]
  end

  def get_detail_path(id, key, opts={})
    ext = opts[:format] ? ".#{opts[:format]}" : ''
    "#{id}/details#{ext}?key=#{key}"
  end

  def get_detail_view
    "generic_report_detail"
  end
end
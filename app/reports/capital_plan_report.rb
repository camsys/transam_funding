class CapitalPlanReport < AbstractReport

  include FiscalYear

  def initialize(attributes = {})
    super(attributes)
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

    labels = ['FY', 'Project', 'Title', 'Scope', '# ALIs', 'Cost', 'Fed $', 'State $', 'Local $']
    formats = [:fiscal_year, :string, :string, :string, :integer, :currency, :currency, :currency, :currency]
    
    # Order by org name, then by FY
    query = CapitalProject.where(organization_id: organization_id_list).joins(:organization).order('organizations.name', :fy_year)

    # Add clauses based on params
    conditions = []
    values = []

    value = params[:start_fy_year] || current_planning_year_year
    conditions << 'capital_projects.fy_year >= ?'
    values << value.to_i 
    
    value = params[:end_fy_year] || current_planning_year_year
    conditions << 'capital_projects.fy_year <= ?'
    values << value.to_i 

    query = query.where(conditions.join(' AND '), *values).eager_load(:activity_line_items, :funding_requests)
    
    data = []
    org_data = []
    current_org = nil
    query.each do |cp|
      row = [
        cp.fy_year,
        cp.project_number,
        cp.title,
        cp.team_ali_code.scope,
        cp.activity_line_items.count,
        cp.total_cost,
        cp.federal_funds,
        cp.state_funds,
        cp.local_funds
      ]
      if current_org != cp.organization
        data << [current_org.name, org_data] if current_org
        org_data = [row]
        current_org = cp.organization
      else
        org_data << row
      end
    end
    data << [current_org.name, org_data]
    
    return {labels: labels, data: data, formats: formats}
  end

  def get_key(row)
    row
  end

  def get_detail_path(id, key, opts={})
    ext = opts[:format] ? ".#{opts[:format]}" : ''
    ""
  end

  def get_detail_view
    "report_alis"
  end
end
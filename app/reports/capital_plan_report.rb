class CapitalPlanReport < AbstractReport

  include FiscalYear

  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_actions
    @actions = [{type: :check_box_collection,
                 group: :group_by,
                 values: [:by_year, :by_agency, :by_scope, :split_sogr]}]

    @actions = [
      {
        type: :select,
        where: :start_fy_year,
        values: get_fiscal_years
      },
      {
        type: :select,
        where: :end_fy_year,
        values: get_fiscal_years
      }
    ]
  end
  
  def get_data(organization_id_list, params)

    labels = ['FY', 'Project', 'Title', 'Scope', 'Cost', 'Fed $', 'State $', 'Local $']
    formats = [:fiscal_year, nil, nil, nil, :currency, :currency, :currency, :currency]
    
    # Default scope orders by project_id
    query = CapitalProject.where(organization_id: organization_id_list)

    # Add clauses based on params
    conditions = []
    values = []
    if params[:start_fy_year].present?
      conditions << 'fy_year >= ?'
      values << params[:start_fy_year].to_i 
    end

    if params[:end_fy_year].present?
      conditions << 'fy_year <= ?'
      values << params[:end_fy_year].to_i 
    end

    query = query.where(conditions.join(' AND '), *values).eager_load(:activity_line_items, :funding_requests)
    
    data = []
    query.each do |cp|
      data << [
        cp.fy_year,
        cp.project_number,
        cp.title,
        cp.team_ali_code.scope,
        cp.total_cost,
        cp.federal_funds,
        cp.state_funds,
        cp.local_funds
      ]
    end
    return {labels: labels, data: data, formats: formats}
  end

  def get_key(row)
    row
  end

  def get_detail_path(key, opts={})
    ext = opts[:format] ? ".#{opts[:format]}" : ''
    "details#{ext}?key=#{key}"
  end

  def get_detail_view
    "report_alis"
  end
end
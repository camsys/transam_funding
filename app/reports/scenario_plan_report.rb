class ScenarioPlanReport < AbstractReport
  include FiscalYear

  KEY_INDEX = 4
  DETAIL_LABELS = ['NAME', FiscalYearHelper.get_fy_label, 'Sub Category', '# Assets', '', 'Cost', 'Federal', 'State', 'Local']
  DETAIL_FORMATS = [:string, :fiscal_year, :string, :integer, :string, :currency, :currency, :currency, :currency]

  def initialize(attributes = {})
    super(attributes)
  end

  def self.get_detail_data(organization_id_list, params)
    query = DraftProjectPhase.joins(:draft_project).includes(:team_ali_code)
                             .where(draft_projects: {object_key: params[:key]})

    data = query.pluck(:id, :name, :fy_year, 'team_ali_codes.code').to_a
    query = query.group('draft_project_phases.id')
    asset_counts = query.joins(:transit_assets).count(:transit_asset_id)
    costs = query.sum(DraftProjectPhase::COST_SUM_SQL_CLAUSE)
    # eager_load implicitly performs left join
    query = query.eager_load(:draft_funding_requests)
    federal = query.map{|p| [p.id, p.federal_allocated]}.to_h
    state = query.map{|p| [p.id, p.state_allocated]}.to_h
    local = query.map{|p| [p.id, p.local_allocated]}.to_h

    data.each do |row|
      id = row[0]
      row << asset_counts[id]
      row << ''
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
        label: "Project #{FiscalYearHelper.get_fy_label} From"
      },
      {
        type: :select,
        where: :end_fy_year,
        values: get_fiscal_years,
        label: 'To'
      },
      {
        type: :select,
        where: :primary_scenario,
        values: ["", "Yes", "No"],
        label: "Is Primary"
      }
    ]
  end

  def get_data(organization_id_list, params)
    labels = ["Project #{FiscalYearHelper.get_fy_label}", 'Organization', 'Scenario', 'Primary Scenario', 'Project', 'object_key', 'Title', 'Scope', '#&nbsp;ALIs', 'Multi Year Project', 'Cost', 'Fed&nbsp;$', 'State&nbsp;$', 'Local&nbsp;$']
    formats = [:fiscal_year, :string, :scenario_url, :boolean, :object_url, :hidden, :string, :string, :integer, :boolean, :currency, :currency, :currency, :currency]

    # Order by org name, then by FY
    query = DraftProject.joins(:scenario).where(scenarios: {organization_id: organization_id_list}).joins(:organization).eager_load(:draft_project_phases).order('organizations.name', 'draft_project_phases.fy_year')

    # Add clauses based on params
    conditions = []
    values = []

    value = params[:start_fy_year] || current_planning_year_year
    conditions << 'draft_project_phases.fy_year >= ?'
    start_year = value.to_i
    values << start_year

    value = params[:end_fy_year] || current_planning_year_year
    conditions << 'draft_project_phases.fy_year <= ?'
    end_year = value.to_i
    values << end_year

    if params[:primary_scenario] && params[:primary_scenario] != ""
      value = params[:primary_scenario]
      if value == "Yes"
        conditions << 'scenarios.primary_scenario = ?'
        values << true
      else
        conditions << '(scenarios.primary_scenario = ? OR scenarios.primary_scenario IS ?)'
        values.push(false, nil)
      end
    end

    # Validation
    if end_year < start_year
      return "To Year cannot be before From Year."
    end

    query = query.where(conditions.join(' AND '), *values)

    data = []
    org_data = []
    current_org = nil
    current_fy = nil
    total_ali_count = total_cost = total_federal_funds = total_state_funds = total_local_funds = 0

    query.each do |dp|
      row = [
        dp.fy_year,
        dp.organization,
        dp.scenario.name,
        dp.scenario.primary_scenario,
        dp.project_number.blank? ? "[No project number]" : dp.project_number,
        dp.object_key,
        dp.title,
        dp.team_ali_code.scope,
        dp.draft_project_phases.count,
        dp.multi_year?,
        dp.cost,
        dp.federal_allocated,
        dp.state_allocated,
        dp.local_allocated
      ]
      if current_org != dp.organization
        if current_org
          org_data << [nil, nil, nil, nil, nil, nil, "Totals for #{fiscal_year(current_fy)}", nil,
                       total_ali_count, nil,
                       total_cost, total_federal_funds, total_state_funds, total_local_funds]
          data << [current_org.name, org_data]
        end
        current_fy = dp.fy_year
        total_ali_count = dp.draft_project_phases.count
        total_cost = dp.cost
        total_federal_funds = dp.federal_allocated
        total_state_funds = dp.state_allocated
        total_local_funds = dp.local_allocated

        org_data = [row]
        current_org = dp.organization
      else
        if current_fy == dp.fy_year
          total_ali_count += dp.draft_project_phases.count
          total_cost += dp.cost
          total_federal_funds += dp.federal_allocated
          total_state_funds += dp.state_allocated
          total_local_funds += dp.local_allocated
        else
          if current_fy
            org_data << [nil, nil, nil, nil, nil, nil, "Totals for #{fiscal_year(current_fy)}", nil,
                         total_ali_count, nil,
                         total_cost, total_federal_funds, total_state_funds, total_local_funds]
          end
          current_fy = dp.fy_year
          total_ali_count = dp.draft_project_phases.count
          total_cost = dp.cost
          total_federal_funds = dp.federal_allocated
          total_state_funds = dp.state_allocated
          total_local_funds = dp.local_allocated
        end
        org_data << row
      end
    end
    if current_org
      org_data << [nil, nil, nil, nil, nil, nil, "Totals for #{fiscal_year(current_fy)}", nil,
                   total_ali_count, nil,
                   total_cost, total_federal_funds, total_state_funds, total_local_funds]
      data << [current_org.name, org_data]
    else
      # Handle the case when no Draft Project are found with the given parameters.
      labels = []
      # Pass a warning message where the organization name would normally go.
      data << ["No projects found for selected organizations in selected years.", []]
    end
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

  def get_object_url(row)
    get_key(row) ? "/draft_projects/#{get_key(row)}".html_safe : nil
  end

  def get_scenario_url(row)
    get_key(row) ? "/scenarios/#{DraftProject.find_by(object_key: get_key(row))&.scenario&.object_key}".html_safe : nil
  end
end
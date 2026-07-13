class ScenarioBudgetReport < AbstractReport
  include TransamFormatHelper

  KEY_INDEX = 5
  LABELS = ['Activity', 'Fund', 'Actual %', 'Allocation']
  FORMATS = [:string, :string, :string, :currency]

  def initialize(attributes = {})
    super(attributes)
  end

  def get_data(organization_id_list, params)
    labels = LABELS
    formats = FORMATS

    # TODO: get this right and note sorting/grouping
    # query = DraftBudgetAllocation.joins(:draft_budget).joins(:draft_funding_request).joins(:draft_project_phase).joins(:draft_project).joins(:scenario).where(scenario: {id: @report_params.scenario_id}).order('draft_projects.name', 'draft_project_phases.fy_year')

    # Mock data
    scenario_name = "ATA SOGR 26-27 to 37-38 #1"
    query = [
      {draft_project: {name: "ATA-26-27-114-1 Shop Equipment Replacement"}, draft_project_phase: {name: "Shop Equipment Replacement"}, draft_budget: {name: "FY 26-27 1514 Discretionary"}, amount: 6774, effective_pct: 96.771},
      {draft_project: {name: "ATA-26-27-114-1 Shop Equipment Replacement"}, draft_project_phase: {name: "Shop Equipment Replacement"}, draft_budget: {name: "ATA Local FY 24-25"}, amount: 226, effective_pct: 3.229},
      {draft_project: {name: "ATA-26-27-114-1 Shop Equipment Replacement"}, draft_project_phase: {name: "Jburg Small Tire Changer"}, draft_budget: {name: "FY 26-27 1514 Discretionary"}, amount: 14516, effective_pct: 96.773},
      {draft_project: {name: "ATA-26-27-114-1 Shop Equipment Replacement"}, draft_project_phase: {name: "Jburg Small Tire Changer"}, draft_budget: {name: "ATA Local FY 24-25"}, amount: 484, effective_pct: 3.227}
    ]

    # TODO: include filters? (assume not)
    # Add clauses based on params
    # conditions = []
    # values = []
    #
    # value = params[:start_fy_year] || current_planning_year_year
    # conditions << 'draft_project_phases.fy_year >= ?'
    # start_year = value.to_i
    # values << start_year
    #
    # value = params[:end_fy_year] || current_planning_year_year
    # conditions << 'draft_project_phases.fy_year <= ?'
    # end_year = value.to_i
    # values << end_year
    #
    # conditions << 'scenarios.fy_year = ?'
    # values << start_year
    #
    # if params[:primary_scenario] && params[:primary_scenario] != ""
    #   value = params[:primary_scenario]
    #   if value == "Yes"
    #     conditions << 'scenarios.primary_scenario = ?'
    #     values << true
    #   else
    #     conditions << '(scenarios.primary_scenario = ? OR scenarios.primary_scenario IS ?)'
    #     values.push(false, nil)
    #   end
    # end
    #
    # # Validation
    # if end_year < start_year
    #   return "To Year cannot be before From Year."
    # end
    #
    # query = query.where(conditions.join(' AND '), *values)

    data = []
    project_data = []
    current_project = nil
    current_activity = nil
    total_project_amount = total_activity_amount = 0

    # TODO: change back to dot notation for actual query data
    query.each do |allocation|
      row = [
        allocation[:draft_project_phase][:name],
        allocation[:draft_budget][:name],
        format_as_percentage(allocation[:effective_pct], 3),
        allocation[:amount]
      ]
      # When current data is for a new project
      if current_project != allocation[:draft_project]
        # If this is not the first row, finalize the data for this project and ALI
        if current_project
          project_data << [nil, nil, "Total", total_activity_amount]
          project_data << [nil, "Project Total", nil, total_project_amount]
          data << [current_project[:name], project_data]
        end
        # Reassign variables based on new project
        current_activity = allocation[:draft_project_phase]
        total_project_amount = allocation[:amount]
        total_activity_amount = allocation[:amount]
        project_data = [row]
        current_project = allocation[:draft_project]
      else
        # If this row is still part of the same ALI, add current row amount to totals
        if current_activity == allocation[:draft_project_phase]
          total_activity_amount += allocation[:amount]
          total_project_amount += allocation[:amount]
        else
          # If this row is for a new ALI and is not the first row of data, add the summary row for the previous ALI
          if current_activity
            project_data << [nil, nil, "Total", total_activity_amount]
          end
          # Set new current ALI, reset the activity amount, and add row amount to project total
          current_activity = allocation[:draft_project_phase]
          total_activity_amount = allocation[:amount]
          total_project_amount += allocation[:amount]
        end
        project_data << row
      end
    end
    # After adding all data rows, include one final ALI summary total row and one final project summary total row for the last project/ALI
    if current_project
      project_data << [nil, nil, "Total", total_activity_amount]
      project_data << [nil, "Project Total", nil, total_project_amount]
      data << [current_project[:name], project_data]
    else
      # Handle the case when no budget allocations are found with the given scenario
      labels = []
      # Pass a warning message where the organization name would normally go.
      data << ["No budget allocations found for selected scenario.", []]
    end
    return {top_header: scenario_name, header_format: :string, labels: labels, data: data, formats: formats}
  end

  def get_key(row)
    row[KEY_INDEX]
  end

  def self.required_params
    [:scenario_id]
  end
end
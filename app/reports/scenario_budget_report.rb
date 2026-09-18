class ScenarioBudgetReport < AbstractReport
  include TransamFormatHelper

  KEY_INDEX = 5
  SUMMARY_LABELS = ['Fund', '', 'Total']
  LABELS = ['Activity', 'Fund', 'Actual %', 'Allocation']
  SUMMARY_FORMATS = [:string, :string, :currency]
  FORMATS = [:string, :string, :string, :currency]

  def initialize(attributes = {})
    super(attributes)
  end

  def get_data(organization_id_list, params)
    summary_labels = SUMMARY_LABELS
    labels = LABELS
    summary_formats = SUMMARY_FORMATS
    formats = FORMATS

    scenario = Scenario.find(params[:scenario_id])
    query = DraftBudgetAllocation.joins(:draft_budget).joins(:draft_funding_request).joins(:draft_project_phase).joins(:draft_project).where(draft_projects: {scenario_id: scenario.id}, draft_project_phases: {fy_year: current_planning_year_year}).order('draft_projects.project_number ASC', 'draft_projects.title ASC', 'draft_project_phases.fy_year DESC')

    data = []
    summary_data = []
    project_data = []
    current_project = nil
    project_name = nil
    current_activity = nil
    total_project_amount = total_activity_amount = 0
    summary_table = {table_header: "Summary", labels: summary_labels, formats: summary_formats, table_data: nil}
    current_budget = nil
    current_source_type = nil
    total_budget_amount = total_source_type_amount = total_scenario_amount = 0

    # Summary table
    query.joins("INNER JOIN funding_templates ON draft_budgets.funding_template_id = funding_templates.id")
         .joins("INNER JOIN funding_sources ON funding_templates.funding_source_id = funding_sources.id")
         .reorder("funding_sources.funding_source_type_id ASC", "draft_budgets.name ASC")
         .each do |allocation|
      # When current data is for a new funding source type
      if current_source_type != allocation.funding_source_type
        # If this is not the first record, finalize the data for this funding source type
        if current_source_type
          summary_data << [current_budget.name, nil, total_budget_amount]
          summary_data << [nil, "Total #{current_source_type.name} Funding", total_source_type_amount]
        end
        # Reassign variables based on new funding source type
        current_source_type = allocation.funding_source_type
        current_budget = allocation.draft_budget
        total_source_type_amount = total_budget_amount = allocation.amount
        total_scenario_amount += allocation.amount
      else
        # If this record is still part of the same budget, add current record amount to totals
        if current_budget == allocation.draft_budget
          total_budget_amount += allocation.amount
          total_source_type_amount += allocation.amount
          total_scenario_amount += allocation.amount
        else
          # If this record is for a new budget and is not the first record of data, add the total row for the previous budget
          if current_budget
            summary_data << [current_budget.name, nil, total_budget_amount]
          end
          # Set new current budget, reset the budget amount, and add allocation amount to funding type total
          current_budget = allocation.draft_budget
          total_budget_amount = allocation.amount
          total_source_type_amount += allocation.amount
          total_scenario_amount += allocation.amount
        end
      end
    end
    # After processing all data records, include one final set of summary total rows for the budget and funding source type, and one total row for the scenario
    if current_source_type
      summary_data << [current_budget.name, nil, total_budget_amount]
      summary_data << [nil, "Total #{current_source_type.name} Funding", total_source_type_amount]
      summary_data << [nil, "Total Grant Agreement Award Amount", total_scenario_amount]
    end
    summary_table[:table_data] = summary_data

    # Main report
    query.each do |allocation|
      row = [
        allocation.draft_project_phase.name,
        allocation.draft_budget.name,
        format_as_percentage(allocation.amount > 0 && allocation.draft_funding_request.total > 0 ? 100*(allocation.amount.to_f/allocation.draft_funding_request.total.to_f) : 0, 3),
        allocation.amount
      ]
      # When current data is for a new project
      if current_project != allocation.draft_project
        # If this is not the first row, finalize the data for this project and ALI
        if current_project
          project_data << [nil, nil, "Total", total_activity_amount]
          project_data << [nil, "Project Total", nil, total_project_amount]
          data << [project_name, project_data]
        end
        # Reassign variables based on new project
        current_activity = allocation.draft_project_phase
        total_project_amount = allocation.amount
        total_activity_amount = allocation.amount
        project_data = [row]
        current_project = allocation.draft_project
        project_name = current_project.project_number.blank? ? current_project.title : "#{current_project.project_number} #{current_project.title}"
      else
        # If this row is still part of the same ALI, add current row amount to totals
        if current_activity == allocation.draft_project_phase
          total_activity_amount += allocation.amount
          total_project_amount += allocation.amount
        else
          # If this row is for a new ALI and is not the first row of data, add the summary row for the previous ALI
          if current_activity
            project_data << [nil, nil, "Total", total_activity_amount]
          end
          # Set new current ALI, reset the activity amount, and add row amount to project total
          current_activity = allocation.draft_project_phase
          total_activity_amount = allocation.amount
          total_project_amount += allocation.amount
        end
        project_data << row
      end
    end
    # After adding all data rows, include one final ALI summary total row and one final project summary total row for the last project/ALI
    if current_project
      project_data << [nil, nil, "Total", total_activity_amount]
      project_data << [nil, "Project Total", nil, total_project_amount]
      data << [project_name, project_data]
    else
      # Handle the case when no budget allocations are found with the given scenario
      labels = []
      # Pass a warning message where the organization name would normally go.
      data << ["No budget allocations found for selected scenario.", []]
    end
    return {top_header: scenario.name, header_format: :string, labels: labels, data: data, formats: formats, summary_table: summary_table}
  end

  def get_key(row)
    row[KEY_INDEX]
  end
end
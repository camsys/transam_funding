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

    scenario = Scenario.find(params[:scenario_id])
    query = DraftBudgetAllocation.joins(:draft_budget).joins(:draft_funding_request).joins(:draft_project_phase).joins(:draft_project).where(draft_projects: {scenario_id: scenario.id}, draft_project_phases: {fy_year: current_planning_year_year}).order('draft_projects.project_number ASC', 'draft_projects.title ASC', 'draft_project_phases.fy_year DESC')

    data = []
    project_data = []
    current_project = nil
    project_name = nil
    current_activity = nil
    total_project_amount = total_activity_amount = 0

    query.each do |allocation|
      row = [
        allocation.draft_project_phase.name,
        allocation.draft_budget.name,
        format_as_percentage(100*(allocation.amount.to_f/allocation.draft_project_phase.cost), 3),
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
    return {top_header: scenario.name, header_format: :string, labels: labels, data: data, formats: formats}
  end

  def get_key(row)
    row[KEY_INDEX]
  end
end
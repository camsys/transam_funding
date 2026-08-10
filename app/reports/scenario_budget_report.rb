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
    total_activity_allocated = total_project_allocated = nil

    query.each do |allocation|
      # When current data is for a new project
      if current_project != allocation.draft_project
        # If this is not the first row, finalize the data for this project and ALI
        if current_project
          project_data << [nil, nil, "Total", total_activity_allocated]
          project_data << [nil, "Project Total", nil, total_project_allocated]
          data << [project_name, project_data]
        end
        # Reassign variables based on new project
        current_activity = allocation.draft_project_phase
        current_project = allocation.draft_project
        total_activity_allocated = current_activity.allocated
        total_project_allocated = total_activity_allocated
        row = [
          current_activity.name,
          allocation.draft_budget.name,
          format_as_percentage(allocation.amount > 0 && total_activity_allocated > 0 ? 100*(allocation.amount.to_f/total_activity_allocated.to_f) : 0, 3),
          allocation.amount
        ]
        project_data = [row]
        project_name = current_project.project_number.blank? ? current_project.title : "#{current_project.project_number} #{current_project.title}"
      else
        unless current_activity == allocation.draft_project_phase
          # If this row is for a new ALI and is not the first row of data, add the summary row for the previous ALI
          if current_activity
            project_data << [nil, nil, "Total", total_activity_allocated]
          end
          # Set new current ALI and its allocation amount, and add new activity allocation to project total
          current_activity = allocation.draft_project_phase
          total_activity_allocated = current_activity.allocated
          total_project_allocated += total_activity_allocated
        end
        row = [
          current_activity.name,
          allocation.draft_budget.name,
          format_as_percentage(allocation.amount > 0 && total_activity_allocated > 0 ? 100*(allocation.amount.to_f/total_activity_allocated.to_f) : 0, 3),
          allocation.amount
        ]
        project_data << row
      end
    end
    # After adding all data rows, include one final ALI summary total row and one final project summary total row for the last project/ALI
    if current_project
      project_data << [nil, nil, "Total", total_activity_allocated]
      project_data << [nil, "Project Total", nil, total_project_allocated]
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
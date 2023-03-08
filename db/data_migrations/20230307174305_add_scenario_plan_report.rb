class AddScenarioPlanReport < ActiveRecord::DataMigration
  def up
    old_report_attributes = Report.find_by(class_name: "CapitalPlanReport").attributes.except("id", "name", "description", "class_name", "created_at", "updated_at")
    scenario_plan_report = Report.new(old_report_attributes)
    scenario_plan_report.name = "Scenario Plan Report"
    scenario_plan_report.description = "Displays a report showing scenario projects with costs and funds. Drilldown to ALI detail."
    scenario_plan_report.class_name = "ScenarioPlanReport"
    scenario_plan_report.save!
  end

  def down
    Report.find_by(class_name: "ScenarioPlanReport").destroy
  end
end
class AddScenarioBudgetReport < ActiveRecord::DataMigration
  def up
    report_attributes = {
      report_type_id: 2,
      name: "Budget Report",
      description: "Reports budget allocations for a scenario, broken down by project and ALI.",
      class_name: "ScenarioBudgetReport",
      view_name: "grp_header_table",
      roles: "guest,user",
      custom_sql: nil,
      show_in_nav: false,
      show_in_dashboard: false,
      chart_type: nil,
      chart_options: nil,
      active: true,
      printable: false,
      exportable: false,
      data_exportable: nil
    }
    Report.create(report_attributes)
  end

  def down
    Report.find_by(class_name: "ScenarioBudgetReport").destroy
  end
end
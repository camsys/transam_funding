class AddFundingReports < ActiveRecord::DataMigration
  def up
    reports = [
        {
            :active => 1,
            :belongs_to => 'report_type',
            :type => "Capital Needs Report",
            :name => 'Needs Versus Funding Statewide Report',
            :class_name => "NeedsFundingReport",
            :view_name => "generic_formatted_table",
            :show_in_nav => 1,
            :show_in_dashboard => 1,
            :printable => true,
            :exportable => true,
            :roles => 'guest,user,manager',
            :description => 'Displays a report showing the total needs by fiscal year versus available funding, broken out by source of funds.',
            :chart_type => '',
            :chart_options => ""
        },
        {
            :active => 1,
            :belongs_to => 'report_type',
            :type => "Capital Needs Report",
            :name => 'ALI Funding Report',
            :class_name => "AliFundingReport",
            :view_name => "generic_table_with_subreports",
            :show_in_nav => 1,
            :show_in_dashboard => 1,
            :printable => true,
            :exportable => true,
            :roles => 'guest,user,manager',
            :description => 'Displays a report showing needs and available funding for ALIs grouped by Year/Agency/Scope/SOGR. Drilldown to ALI detail.',
            :chart_type => '',
            :chart_options => ""
        },
        {
            :active => 1,
            :belongs_to => 'report_type',
            :type => "Capital Needs Report",
            :name => 'Capital Plan Report',
            :class_name => "CapitalPlanReport",
            :view_name => "grp_header_table_with_subreports",
            :show_in_nav => 1,
            :show_in_dashboard => 1,
            :printable => true,
            :exportable => true,
            :roles => 'guest,user,manager',
            :description => 'Displays a report showing capital projects with costs and funds. Drilldown to ALI detail.',
            :chart_type => '',
            :chart_options => ""
        },
        {
            :active => 1,
            :belongs_to => 'report_type',
            :type => "Capital Needs Report",
            :name => 'Bond Request Report',
            :class_name => "BondRequestReport",
            :view_name => "generic_formatted_table",
            :show_in_nav => 1,
            :show_in_dashboard => 0,
            :printable => true,
            :exportable => true,
            :roles => 'manager',
            :description => 'Displays a list of bond requests in a date range.',
            :chart_type => '',
            :chart_options => ""
        }
    ]

    reports.each do |row|
      if Report.find_by(class_name: row[:class_name]).nil?
        x = Report.new(row.except(:belongs_to, :type))
        x.report_type = ReportType.where(:name => row[:type]).first
        x.save!
      else
        x = Report.find_by(class_name: row[:class_name])
        x.update!(row.except(:belongs_to, :type))
      end
    end
  end
end
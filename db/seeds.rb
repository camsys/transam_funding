#encoding: utf-8

# determine if we are using postgres or mysql
is_mysql = (ActiveRecord::Base.configurations[Rails.env]['adapter'].include? 'mysql2')
is_sqlite =  (ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'sqlite3')

#------------------------------------------------------------------------------
#
# Lookup Tables
#
# These are the lookup tables for TransAM Funding
#
#------------------------------------------------------------------------------

puts "======= Processing TransAM Funding Lookup Tables  ======="

funding_template_types = [
    {:active => 1, :name => 'Capital', :description => 'Capital Funding Template'},
    {:active => 1, :name => 'Operating', :description => 'Operating Funding Template'},
    {:active => 1, :name => 'Debt Service', :description => 'Debt Service Funding Template'},
    {:active => 1, :name => 'Other', :description => 'Other Funding Template'},
]

funding_bucket_types = [
    {:active => 1, :name => 'Existing Grant', :description => 'Existing Grant'},
    {:active => 1, :name => 'Formula', :description => 'Formula Bucket'},
    {:active => 1, :name => 'Fund', :description => 'Fund'},
]
capital_plan_types = [
    {name: 'Transit Capital Plan', description: 'Transit Capital Plan', active: true}
]
capital_plan_module_types = [
    {capital_plan_type_id: 1, name: 'Preparation', class_name: 'BaseCapitalPlanModule', strict_action_sequence: false, sequence: 1, active: true},
    {capital_plan_type_id: 1, name: 'Unconstrained Plan', class_name: 'BaseCapitalPlanModule', strict_action_sequence: false, sequence: 2, active: true},
    {capital_plan_type_id: 1, name: 'Funding', class_name: 'BaseCapitalPlanModule', strict_action_sequence: false, sequence: 3, active: true},
    {capital_plan_type_id: 1, name: 'Constrained Plan', class_name: 'ConstrainedCapitalPlanModule', strict_action_sequence: false, sequence: 4, active: true},
    {capital_plan_type_id: 1, name: 'Final Review', class_name: 'ReviewCapitalPlanModule', strict_action_sequence: true, sequence: 5, active: true}
]
capital_plan_action_types = [
    {capital_plan_type_id: 1, capital_plan_module_type_id: 1, name: 'Assets Updated', class_name: 'AssetPreparationCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},
    {capital_plan_type_id: 1, capital_plan_module_type_id: 1, name: 'Funding Verified', class_name: 'BaseCapitalPlanAction', roles: 'transit_manager,manager', sequence: 2, active: true},

    {capital_plan_type_id: 1, capital_plan_module_type_id: 2, name: 'Agency Approval', class_name: 'BaseCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},
    {capital_plan_type_id: 1, capital_plan_module_type_id: 2, name: 'State Approval', class_name: 'BaseCapitalPlanAction', roles: 'manager', sequence: 2, active: true},

    {capital_plan_type_id: 1, capital_plan_module_type_id: 3, name: 'Funding Complete', class_name: 'FundingCompleteConstrainedCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},

    {capital_plan_type_id: 1, capital_plan_module_type_id: 4, name: 'Agency Approval', class_name: 'BaseCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},
    {capital_plan_type_id: 1, capital_plan_module_type_id: 4, name: 'State Approval', class_name: 'BaseCapitalPlanAction', roles: 'manager', sequence: 2, active: true},

    {capital_plan_type_id: 1, capital_plan_module_type_id: 5, name: 'Approver 1', class_name: 'BaseCapitalPlanAction', roles: 'approver_one', sequence: 1, active: true},
    {capital_plan_type_id: 1, capital_plan_module_type_id: 5, name: 'Approver 2', class_name: 'BaseCapitalPlanAction', roles: 'approver_two', sequence: 2, active: true},
    {capital_plan_type_id: 1, capital_plan_module_type_id: 5, name: 'Approver 3', class_name: 'BaseCapitalPlanAction', roles: 'approver_three', sequence: 3, active: true},
    {capital_plan_type_id: 1, capital_plan_module_type_id: 5, name: 'Approver 4', class_name: 'BaseCapitalPlanAction', roles: 'approver_four', sequence: 4, active: true},
    {capital_plan_type_id: 1, capital_plan_module_type_id: 5, name: 'Archive', class_name: 'BaseCapitalPlanAction', roles: 'admin', sequence: 4, active: true}
]

system_config_extensions = [
    {class_name: 'FundingSource', extension_name: 'FundingFundingSource', active: true},
    {class_name: 'CapitalProject', extension_name: 'TransamFundableCapitalProject', active: true},
    {class_name: 'ActivityLineItem', extension_name: 'TransamFundable', active: true}
]


lookup_tables = %w{ funding_template_types funding_bucket_types capital_plan_types capital_plan_module_types capital_plan_action_types}
merge_tables = %w{ system_config_extensions }


lookup_tables.each do |table_name|
  puts "  Loading #{table_name}"
  if is_mysql
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_name};")
  elsif is_sqlite
    ActiveRecord::Base.connection.execute("DELETE FROM #{table_name};")
  else
    ActiveRecord::Base.connection.execute("TRUNCATE #{table_name} RESTART IDENTITY;")
  end
  data = eval(table_name)
  klass = table_name.classify.constantize
  data.each do |row|
    x = klass.new(row)
    x.save!
  end
end

merge_tables.each do |table_name|
  puts "  Merging #{table_name}"
  data = eval(table_name)
  klass = table_name.classify.constantize
  data.each do |row|
    x = klass.new(row.except(:belongs_to, :type))
    x.save!
  end
end

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

table_name = 'reports'
puts "  Merging #{table_name}"
data = eval(table_name)
data.each do |row|
  x = Report.new(row.except(:belongs_to, :type))
  x.report_type = ReportType.where(:name => row[:type]).first
  x.save!
end
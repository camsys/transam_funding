namespace :transam do
  task create_bucket_types: :environment do
    formula_bucket_type = FundingBucketType.new(:active => 1, :name => 'Formula', :description => 'Formula Bucket')
    existing_bucket_type = FundingBucketType.new(:active => 1, :name => 'Existing Grant', :description => 'Existing Grant')
    grant_application_bucket_type = FundingBucketType.new(:active => 1, :name => 'Fund', :description => 'Fund')

    formula_bucket_type.save
    existing_bucket_type.save
    grant_application_bucket_type.save
  end

  desc "Build Capital Plan Workflow"
  task build_capital_plan_structure: :environment do
    capital_plan_types = [
        {id: 1, name: 'Transit Capital Plan', description: 'Transit Capital Plan', active: true}
    ]
    capital_plan_module_types = [
        {id: 1, capital_plan_type_id: 1, name: 'Preparation', class_name: 'BaseCapitalPlanModule', strict_action_sequence: false, sequence: 1, active: true},
        {id: 2, capital_plan_type_id: 1, name: 'Unconstrained Plan', class_name: 'BaseCapitalPlanModule', strict_action_sequence: false, sequence: 2, active: true},
        {id: 3, capital_plan_type_id: 1, name: 'Funding', class_name: 'ConstrainedCapitalPlanModule', strict_action_sequence: false, sequence: 3, active: true},
        {id: 4, capital_plan_type_id: 1, name: 'Constrained Plan', class_name: 'ConstrainedCapitalPlanModule', strict_action_sequence: false, sequence: 4, active: true},
        {id: 5, capital_plan_type_id: 1, name: 'Final Review', class_name: 'ReviewCapitalPlanModule', strict_action_sequence: true, sequence: 5, active: true}
    ]
    capital_plan_action_types = [
        {id: 1, capital_plan_type_id: 1, capital_plan_module_type_id: 1, name: 'Assets Updated', class_name: 'AssetPreparationCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},
        {id: 2, capital_plan_type_id: 1, capital_plan_module_type_id: 1, name: 'Updates OK', class_name: 'AssetOverridePreparationCapitalPlanAction', roles: 'manager', sequence: 2, active: true},
        {id: 3, capital_plan_type_id: 1, capital_plan_module_type_id: 1, name: 'Funds Verified', class_name: 'BaseCapitalPlanAction', roles: 'transit_manager,manager', sequence: 2, active: true},

        {id: 4, capital_plan_type_id: 1, capital_plan_module_type_id: 2, name: 'Agency Approval', class_name: 'BaseCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},
        {id: 5, capital_plan_type_id: 1, capital_plan_module_type_id: 2, name: 'State Approval', class_name: 'BaseCapitalPlanAction', roles: 'manager', sequence: 2, active: true},

        {id: 6, capital_plan_type_id: 1, capital_plan_module_type_id: 3, name: 'Funding Complete', class_name: 'FundingCompleteConstrainedCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},

        {id: 7, capital_plan_type_id: 1, capital_plan_module_type_id: 4, name: 'Agency Approval', class_name: 'BaseCapitalPlanAction', roles: 'transit_manager,manager', sequence: 1, active: true},
        {id: 8, capital_plan_type_id: 1, capital_plan_module_type_id: 4, name: 'State Approval', class_name: 'BaseCapitalPlanAction', roles: 'manager', sequence: 2, active: true},

        {id: 9, capital_plan_type_id: 1, capital_plan_module_type_id: 5, name: 'Approver 1', class_name: 'BaseCapitalPlanAction', roles: 'approver_one', sequence: 1, active: true},
        {id: 10, capital_plan_type_id: 1, capital_plan_module_type_id: 5, name: 'Approver 2', class_name: 'BaseCapitalPlanAction', roles: 'approver_two', sequence: 2, active: true},
        {id: 11, capital_plan_type_id: 1, capital_plan_module_type_id: 5, name: 'Approver 3', class_name: 'BaseCapitalPlanAction', roles: 'approver_three', sequence: 3, active: true},
        {id: 12, capital_plan_type_id: 1, capital_plan_module_type_id: 5, name: 'Approver 4', class_name: 'BaseCapitalPlanAction', roles: 'approver_four', sequence: 4, active: true},
        {id: 13, capital_plan_type_id: 1, capital_plan_module_type_id: 5, name: 'Archive', class_name: 'BaseCapitalPlanAction', roles: 'admin', sequence: 5, active: true}
    ]

    CapitalPlanType.destroy_all
    CapitalPlanModuleType.destroy_all
    CapitalPlanActionType.destroy_all
    CapitalPlan.destroy_all

    plan_tables = %w{ capital_plan_types capital_plan_module_types capital_plan_action_types }

    plan_tables.each do |table_name|
      puts "  Loading #{table_name}"
      data = eval(table_name)
      klass = table_name.classify.constantize
      data.each do |row|
        x = klass.new(row)
        x.save!
      end
    end

    Organization.update_all(capital_plan_type_id: 1)
    ActivityLineItem.update_all(is_planning_complete: false)

    roles = [
        {name: 'approver_one', weight: 11, resource_id: Role.find_by(name: 'manager').id, resource_type: 'Role', privilege: true, label: 'Approver 1'},
        {name: 'approver_two', weight: 12, resource_id: Role.find_by(name: 'manager').id, resource_type: 'Role', privilege: true, label: 'Approver 2'},
        {name: 'approver_three', weight: 13, resource_id: Role.find_by(name: 'manager').id, resource_type: 'Role', privilege: true, label: 'Approver 3'},
        {name: 'approver_four', weight: 14, resource_id: Role.find_by(name: 'manager').id, resource_type: 'Role', privilege: true, label: 'Approver 4'},
    ]
    roles.each do |role|
      if Role.find_by(name: role[:name]).nil?
        Role.create!(role)
      end
    end
  end

  desc "Add funding reports"
  task add_funding_reports: :environment do
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
          :view_name => "capital_plan_with_alis",
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
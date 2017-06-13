class AliFundingReport < AbstractReport

  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_actions
    @actions = [{type: :check_box_collection,
                 group: :group_by,
                 values: [:by_year, :by_agency, :by_scope, :split_sogr]}]
  end
  
  def get_data(organization_id_list, params)

    common_labels = ['# ALIs', '# Assets', 'Cost', 'Funded', 'Balance']
    common_formats = [:integer, :integer, :currency, :currency, :currency]
    labels = []
    formats = []
    
    # Default scope orders by project_id
    query = ActivityLineItem.unscoped.joins(:team_ali_code, :capital_project)
            .includes(:team_ali_code, capital_project: :organization)
            .where(capital_projects: {organization_id: organization_id_list})

    # Add clauses based on params
    # For initial static report
    (params[:group_by] || []).each do |group|
      labels << group.to_s.titleize.split[1]
      case group.to_sym
      when :by_year
        formats << :fiscal_year
        group_by = order_by = 'activity_line_items.fy_year'
      when :by_agency
        formats << :string
        group_by = order_by = 'organizations.short_name'
      when :by_scope
        formats << :string
        group_by = order_by = 'concat(substr(code, 1, 2), substr(code, 4, 1))'
      when :split_sogr
        formats << :boolean
        order_by = group_by = 'capital_projects.sogr'
      end
      query = query.group(group_by).order(order_by)
    end

    # Generate queries for each column
    ali_counts = query.count
    asset_counts = query.joins(:assets).count
    costs = query.sum(ActivityLineItem::COST_SUM_SQL_CLAUSE)
    # eager_load implicitly performs left join
    funded = query.eager_load(:funding_requests).sum('funding_requests.federal_amount + funding_requests.state_amount + funding_requests.local_amount')
    
    data = []
    if params[:group_by]
      # Add initial columns and ALI count to data
      ali_counts.each do |k, v|
        data << [*k, v]
      end
      # Add asset count
      asset_counts.each_with_index do |(k, v), i|
        data[i] << v
      end
      # Add cost
      costs.each_with_index do |(k, v), i|
        data[i] << v
      end
      # Add funding, 
      funded.each_with_index do |(k, v), i|
        data[i] << v
      end
    else
      data << [ali_counts, asset_counts, costs, funded]
    end
    # Balance
    data.each do |row|
      row << row[-2] - row[-1]
    end
    
    return {labels: labels + common_labels, data: data, formats: formats + common_formats}
  end
end
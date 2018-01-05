class AliFundingReport < AbstractReport

  COMMON_LABELS = ['# ALIs', '# Assets', 'Cost', 'Funded', 'Balance']
  COMMON_FORMATS = [:integer, :integer, :currency, :currency, :currency]
  DETAIL_LABELS = ['NAME', 'FY', 'Sub Category', 'Pinned', '# Assets', 'Cost', 'Funded', 'Balance']
  DETAIL_FORMATS = [:string, :fiscal_year, :string, :boolean, :integer, :currency, :currency, :currency]

  def self.get_detail_data(organization_id_list, params)
    # Default scope orders by project_id
    query = ActivityLineItem.unscoped.distinct.joins(:team_ali_code, :capital_project)
            .eager_load(:assets)
            .includes(:team_ali_code, capital_project: :organization)
            .where(capital_projects: {organization_id: organization_id_list})

    key = params[:key].split('-')

    pinned_status_type = ReplacementStatusType.find_by(name: 'Pinned')
    if params[:pinned].to_i == 1
      query = query.where(capital_projects: {notional: false}, assets: {replacement_status_type_id: pinned_status_type.id})
    elsif params[:pinned].to_i == -1
      query = query.where('assets.replacement_status_type_id != ? OR assets.replacement_status_type_id IS NULL', pinned_status_type.id)
    end
    
    (params[:group_by] || []).each_with_index do |group, i|
      case group.to_sym
      when :by_year
        clause = 'activity_line_items.fy_year = ?'
      when :by_agency
        clause = 'organizations.short_name = ?'
      when :by_scope
        clause = 'concat(substr(code, 1, 2), substr(code, 4, 1)) = ?'
      when :split_sogr
        clause = 'capital_projects.sogr = ?'
      end
      query = query.where(clause, key[i])
    end
    
    data = query.pluck(:id, :name, :fy_year, 'team_ali_codes.code', 'assets.replacement_status_type_id').to_a
    query = query.group('activity_line_items.id')
    asset_counts = query.joins(:assets).count(:asset_id)
    costs = query.sum(ActivityLineItem::COST_SUM_SQL_CLAUSE)
    # eager_load implicitly performs left join
    funded = query.eager_load(:funding_requests).sum('funding_requests.federal_amount + funding_requests.state_amount + funding_requests.local_amount')
    data.each do |row|
      row[-1] = row[-1].to_i == pinned_status_type.id ? true : false
      row << asset_counts[row[0]]
      row << costs[row[0]]
      row << funded[row[0]]
      row << row[-2] - row[-1] # balance
      row.shift                # remove initial id
    end

    {labels: DETAIL_LABELS, data: data, formats: DETAIL_FORMATS}
  end
  
  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_actions
    @actions = [
        {
            type: :check_box_collection,
            group: :group_by,
            values: [:by_year, :by_agency, :by_scope, :split_sogr]
        },
        {
            type: :select,
            where: :pinned,
            values: [['All', 0], ['Pinned', 1], ['Not Pinned', -1]],
            label: 'Pinned?'
        }

    ]
  end
  
  def get_data(organization_id_list, params)

    labels = []
    formats = []
    
    # Default scope orders by project_id
    query = ActivityLineItem.unscoped.joins(:team_ali_code, :capital_project)
            .includes(:team_ali_code, capital_project: :organization)
            .where(capital_projects: {organization_id: organization_id_list})

    pinned_status_type = ReplacementStatusType.find_by(name: 'Pinned')
    if params[:pinned].to_i == 1
      query = query.eager_load(:assets).where(capital_projects: {notional: false}, assets: {replacement_status_type_id: pinned_status_type.id})
    elsif params[:pinned].to_i == -1
      query = query.eager_load(:assets).where('assets.replacement_status_type_id != ? OR assets.replacement_status_type_id IS NULL', pinned_status_type.id)
    end

    params[:group_by] = ['by_year', 'by_agency'] if params[:group_by].nil? && params[:button].nil?
    # Add clauses based on params
    @clauses = []
    @group_by = params[:group_by] ? {group_by: params[:group_by]} : {}
    @group_by[:pinned] = params[:pinned].to_i

    (params[:group_by] || []).each do |group|
      labels << group.to_s.titleize.split[1]
      case group.to_sym
      when :by_year
        formats << :fiscal_year
        clause = 'activity_line_items.fy_year'
      when :by_agency
        formats << :string
        clause = 'organizations.short_name'
      when :by_scope
        formats << :string
        clause = 'concat(substr(code, 1, 2), substr(code, 4, 1))'
      when :split_sogr
        formats << :boolean
        clause = 'capital_projects.sogr'
      end
      @clauses << clause
      query = query.group(clause).order(clause)
    end

    # Generate queries for each column
    ali_counts = query.count
    costs = query.sum(ActivityLineItem::COST_SUM_SQL_CLAUSE)
    # eager_load implicitly performs left join
    asset_counts = query.eager_load(:assets).count(:asset_id)
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

    return {labels: labels + COMMON_LABELS, data: data, formats: formats + COMMON_FORMATS}
  end

  def get_key(row)
    row.slice(0, @clauses.count).join('-')
  end

  def get_detail_path(id, key, opts={})
    ext = opts[:format] ? ".#{opts[:format]}" : ''
    "#{id}/details#{ext}?key=#{key}&#{@group_by.to_query}"
  end

  def get_detail_view
    "generic_report_detail"
  end

end
AbstractCapitalProjectsController.class_eval do

  #-----------------------------------------------------------------------------
  # Return a possibly filtered set of capital projects. Sets the following
  # view variables
  #   @projects                     -- list of matching capital projects
  #   @org_filter                   -- list of selected organization ids
  #   @fiscal_year_filter           -- list of selected fiscal years
  #   @capital_project_type_filter  -- list of selected capital project types
  #   @capital_project_flag_filter  -- list of selected capital project flags
  #   @asset_subtype_filter         -- list of selected asset subtype ids
  #   @funding_source_filter        -- list of selected funding source ids
  #-----------------------------------------------------------------------------
  def get_projects

    @user_activity_line_item_filter = current_user.user_activity_line_item_filter

    # Start to set up the query
    conditions  = []
    values      = []

    #-----------------------------------------------------------------------------
    #
    # Steps
    #
    #
    # 1. parameters on assets within ALIs
    # 2. parameters on ALIs within projects
    # 3. parameters on projects
    #
    # 1. Search for assets that meet given parameters (type, subtype, etc.) Returns all ALIs with those assets.
    # 2. Given ALIs from above, return subset that meet ALI parameters. Get projects from that subset.
    # 3. Given projects from above return all projects that meet project parameters.
    #
    #-----------------------------------------------------------------------------


    #-----------------------------------------------------------------------------
    # Project parameters
    #-----------------------------------------------------------------------------

    # org id is not tied to ALI filter
    # org id is used in scheduler though not necessary but all links specify looking at a single org at a time
    # other functionality like planning does not require
    if params[:org_id].blank?
      conditions << 'organization_id IN (?)'
      values << @organization_list
    else
      @org_id = params[:org_id].to_i
      conditions << 'organization_id = ?'
      values << @org_id
    end


    @capital_project_flag_filter = []

    capital_project_types = (@user_activity_line_item_filter.try(:capital_project_type_id).blank? ? [] : [@user_activity_line_item_filter.capital_project_type_id] )
    sogr_types = []
    if @user_activity_line_item_filter.try(:sogr_type) == 'SOGR'
      sogr_types = [CapitalProjectType.find_by(name: 'Replacement').id]
      conditions << 'sogr = ?'
      values << true
    elsif @user_activity_line_item_filter.try(:sogr_type) == 'Non-SOGR'
      conditions << 'sogr = ?'
      values << false
    end

    @capital_project_type_filter = (capital_project_types & sogr_types)
    unless @capital_project_type_filter.empty?
      conditions << 'capital_project_type_id IN (?)'
      values << @capital_project_type_filter
    end

    #-----------------------------------------------------------------------------


    #-----------------------------------------------------------------------------
    # Asset parameters
    #-----------------------------------------------------------------------------

    # Filter by asset type and subtype. Requires joining across CP <- ALI <- ALI-Assets <- Assets
    asset_conditions  = []
    asset_values      = []
    if @user_activity_line_item_filter.try(:asset_subtype_id).present?
      @asset_subtype_filter = [@user_activity_line_item_filter.asset_subtype_id]
      asset_conditions << 'asset_subtype_id IN (?)'
      asset_values << @asset_subtype_filter
    elsif @user_activity_line_item_filter.try(:asset_type_id).present?
      @asset_subtype_filter = AssetType.find_by(id: @user_activity_line_item_filter.asset_type_id).asset_subtypes.ids
      asset_conditions << 'asset_subtype_id IN (?)'
      asset_values << @asset_subtype_filter
    end

    # filter by backlog
    if @user_activity_line_item_filter.try(:in_backlog)
      asset_conditions << 'in_backlog = ?'
      asset_values << true
    end

    # always filter assets by org params
    asset_conditions << 'organization_id IN (?)'
    asset_values << values[0]

    ali_asset_conditions = []
    ali_asset_values = []
    unless asset_conditions.empty?
      ali_asset_conditions << 'activity_line_items_assets.asset_id IN (?)'
      ali_asset_values << Asset.where(asset_conditions.join(' AND '), *asset_values).pluck(:id)
    end

    #-----------------------------------------------------------------------------


    #-----------------------------------------------------------------------------
    # ALI parameters
    #-----------------------------------------------------------------------------

    # TEAM ALI code
    if @user_activity_line_item_filter.try(:team_ali_code_id).blank?
      @team_ali_code_filter = []
    else
      @team_ali_code_filter = [@user_activity_line_item_filter.team_ali_code_id]

      ali_asset_conditions << 'activity_line_items_assets.activity_line_item_id IN (?)'
      ali_asset_values << ActivityLineItem.where(team_ali_code_id: @team_ali_code_filter).ids
    end


    unless ali_asset_conditions.empty?
      alis = ActivityLineItem.joins('INNER JOIN activity_line_items_assets ON activity_line_items_assets.activity_line_item_id = activity_line_items.id').where(ali_asset_conditions.join(' AND '), *ali_asset_values)
    end

    funding_bucket = @user_activity_line_item_filter.try(:funding_bucket_id)
    if funding_bucket
      alis = alis.joins(:funding_requests).where('funding_requests.federal_funding_line_item_id = ? OR funding_requests.state_funding_line_item_id = ? OR funding_requests.local_funding_line_item_id = ?', funding_bucket, funding_bucket, funding_bucket)
    end

    if @user_activity_line_item_filter.try(:not_fully_funded)
      alis = alis.joins(
          'LEFT JOIN (
            SELECT SUM(federal_amount + state_amount + local_amount) AS total_amount, activity_line_item_id
            FROM `funding_requests`  GROUP BY `funding_requests`.`activity_line_item_id`
          ) AS sum_table
          ON sum_table.activity_line_item_id = activity_line_items.id'
      ).where('sum_table.total_amount IS NULL OR sum_table.total_amount < activity_line_items.estimated_cost')
    end

    if alis
      conditions << 'capital_projects.id IN (?)'
      values << alis.pluck(:capital_project_id).uniq
    end

    #-----------------------------------------------------------------------------
    # Parse non-common filters
    # filter values come from request params

    @fiscal_year_filter = params[:fiscal_year_filter]

    if @fiscal_year_filter.blank?
      @fiscal_year_filter = []
    else
      conditions << 'capital_projects.fy_year IN (?)'
      values << @fiscal_year_filter
    end

    # Get the initial list of capital projects. These might need to be filtered further if the user specified a funding source filter
    @projects = CapitalProject.where(conditions.join(' AND '), *values).order(:fy_year, :capital_project_type_id, :created_at)

  end
end

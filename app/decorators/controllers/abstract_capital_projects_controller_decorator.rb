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

    # Use ALI as the base relation to deal with asset & ALI filters
    @alis = ActivityLineItem.active.distinct
    no_ali_or_asset_params_exist = true

    #-----------------------------------------------------------------------------
    # Asset parameters
    #-----------------------------------------------------------------------------

    # Filter by asset type and subtype. Requires joining across CP <- ALI <- ALI-Assets <- Assets
    asset_search = Hash.new
    asset_table = Rails.application.config.asset_base_class_name.constantize.table_name
    asset_search[asset_table.to_sym] = Hash.new

    if @user_activity_line_item_filter.try(:asset_subtypes).present?
      @asset_subtype_filter = @user_activity_line_item_filter.asset_subtypes.split(',')

      asset_search[asset_table.to_sym][:asset_subtype_id] = @asset_subtype_filter
      no_ali_or_asset_params_exist = false
    elsif @user_activity_line_item_filter.try(:asset_types).present? && (Rails.application.config.asset_base_class_name.constantize.column_names.include? :asset_type_id)
      @asset_subtype_filter = AssetSubtype.where(asset_type_id: @user_activity_line_item_filter.asset_types.split(',')).pluck(:id)
      asset_search[asset_table.to_sym][:asset_subtype_id] = @asset_subtype_filter
      no_ali_or_asset_params_exist = false
    end

    if @user_activity_line_item_filter.try(:fta_asset_classes).present?
      asset_search[:transit_assets] = {fta_asset_class_id: @user_activity_line_item_filter.fta_asset_classes.split(',')}
      no_ali_or_asset_params_exist = false
    end

    # filter by backlog
    if @user_activity_line_item_filter.try(:in_backlog)
      asset_search[asset_table.to_sym][:in_backlog] = true
      no_ali_or_asset_params_exist = false
    end

    if @user_activity_line_item_filter.try(:asset_query_string)
      asset_search[asset_table.to_sym][:object_key] = Rails.application.config.asset_base_class_name.constantize.find_by_sql(@user_activity_line_item_filter.asset_query_string).map{|x| x.object_key}
      no_ali_or_asset_params_exist = false
    end

    unless asset_search[asset_table.to_sym].empty? && asset_search.keys.count == 1

      asset_search[asset_table.to_sym][:organization_id] = @organization_list

      @alis = @alis.joins(:assets).where(asset_search)

      if Rails.application.config.asset_base_class_name == 'TransamAsset'
        @alis = @alis.joins("INNER JOIN `transit_assets` ON `transam_assets`.`transam_assetible_id` = `transit_assets`.`id` AND `transam_assets`.`transam_assetible_type` = 'TransitAsset'")
      end
    end
    #-----------------------------------------------------------------------------

    #-----------------------------------------------------------------------------
    # Bucket related
    #-----------------------------------------------------------------------------


    if @user_activity_line_item_filter.try(:funding_buckets)
      funding_buckets = @user_activity_line_item_filter.funding_buckets.split(',')
    else
      funding_buckets = []
    end
    if @user_activity_line_item_filter.try(:funding_bucket_query_string)
      funding_buckets = funding_buckets + FundingBucket.find_by_sql(@user_activity_line_item_filter.funding_bucket_query_string).map{|f| f.id}
    end

    if funding_buckets.any?
      @alis = @alis.joins(:funding_requests).where('funding_requests.federal_funding_line_item_id IN (?) OR funding_requests.state_funding_line_item_id IN (?) OR funding_requests.local_funding_line_item_id IN (?)', funding_buckets, funding_buckets, funding_buckets)
      no_ali_or_asset_params_exist = false
    end

    if @user_activity_line_item_filter.try(:not_fully_funded)
      @alis = @alis.joins(
          'LEFT JOIN (
            SELECT SUM(federal_amount + state_amount + local_amount) AS total_amount, activity_line_item_id
            FROM `funding_requests`  GROUP BY `funding_requests`.`activity_line_item_id`
          ) AS sum_table
          ON sum_table.activity_line_item_id = activity_line_items.id'
      ).where("sum_table.total_amount IS NULL OR sum_table.total_amount < (#{ActivityLineItem::COST_SUM_SQL_CLAUSE})")
      no_ali_or_asset_params_exist = false
    end



    #-----------------------------------------------------------------------------

    #-----------------------------------------------------------------------------
    # CapitalProject specific
    #-----------------------------------------------------------------------------
    # get the projects based on filtered ALIs
    @projects = CapitalProject.includes(:capital_project_type,:team_ali_code).active
    unless no_ali_or_asset_params_exist  # dont impose ALI/asset conditions unless they were in the params
      @projects = CapitalProject.includes(:capital_project_type,:team_ali_code).where(id: @alis.distinct.pluck(:capital_project_id))
    end

    # org id is not tied to ALI filter
    # org id is used in scheduler though not necessary but all links specify looking at a single org at a time
    # other functionality like planning does not require
    conditions << 'capital_projects.organization_id IN (?)'
    values << @organization_list

    @capital_project_flag_filter = []

    capital_project_types = (@user_activity_line_item_filter.try(:capital_project_type_id).blank? ? [] : [@user_activity_line_item_filter.capital_project_type_id] )
    sogr_types = []
    if @user_activity_line_item_filter.try(:sogr_type) == 'SOGR'
      sogr_types = [CapitalProjectType.find_by(name: 'Replacement').id]
      conditions << 'capital_projects.sogr = ?'
      values << true
    elsif @user_activity_line_item_filter.try(:sogr_type) == 'Non-SOGR'
      conditions << 'capital_projects.sogr = ?'
      values << false
    end

    @capital_project_type_filter = (capital_project_types & sogr_types)
    unless @capital_project_type_filter.empty?
      conditions << 'capital_projects.capital_project_type_id IN (?)'
      values << @capital_project_type_filter
    end

    # TEAM ALI code
    if @user_activity_line_item_filter.try(:team_ali_codes).blank?
      @team_ali_code_filter = []
    else
      @team_ali_code_filter = @user_activity_line_item_filter.team_ali_codes.split(',')

      conditions << 'capital_projects.team_ali_code_id IN (?)'
      values << @team_ali_code_filter
    end

    if @user_activity_line_item_filter.try(:planning_year)
      @fy_year_filter = [current_planning_year_year]

      conditions << 'capital_projects.fy_year IN (?)'
      values << @fy_year_filter
    else
      @fy_year_filter = []
    end

    # District
    if @user_activity_line_item_filter.try(:districts).blank?
      @district_filter = []
    else
      @district_filter = @user_activity_line_item_filter.districts.split(',')
      conditions << 'capital_projects.id IN (SELECT DISTINCT capital_projects_districts.capital_project_id FROM capital_projects_districts WHERE capital_projects_districts.district_id IN (?))'
      values << @district_filter
    end

    #-----------------------------------------------------------------------------


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
    #-----------------------------------------------------------------------------

    # final results
    @projects = @projects.where(conditions.join(' AND '), *values).order(:fy_year, :project_number)

    @alis = ActivityLineItem.where(capital_project_id: @projects.ids)
  end
end

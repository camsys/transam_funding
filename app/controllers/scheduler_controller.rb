class SchedulerController < OrganizationAwareController

  before_filter :set_view_vars,  :only =>    [:index, :loader, :scheduler_action, :scheduler_ali_action, :scheduler_swimlane_action, :edit_asset_in_modal]

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Scheduler", :scheduler_index_path

  # Include the fiscal year mixin
  include FiscalYear

  # Controller actions that can be invoked from the view to manuipulate assets
  REPLACE_ACTION              = '1'
  REHABILITATE_ACTION         = '2'
  REMOVE_FROM_SERVICE_ACTION  = '3'
  RESET_ACTION                = '4'

  # Controller actions that can be invoked from the view to manuipulate ALIs
  ALI_MOVE_YEAR_ACTION    = '1'
  ALI_UPDATE_COST_ACTION  = '2'
  ALI_REMOVE_ACTION       = '3'
  ALI_ADD_FUND_ACTION     = '4'
  ALI_EDIT_FUND_ACTION    = '5'
  ALI_REMOVE_FUND_ACTION  = '6'

  ACTIONS = [
    ["Replace", REPLACE_ACTION],
    ["Rehabilitate", REHABILITATE_ACTION],
    ["Remove from service (no replacement)", REMOVE_FROM_SERVICE_ACTION],
    ["Reset to policy", RESET_ACTION]
  ]


  YES = '1'
  NO = '0'

  BOOLEAN_SELECT = [
    ['Yes', YES],
    ['No', NO]
  ]

  # Returns the list of assets that are scheduled for replacement/rehabilitation in the given
  # fiscal years.
  def index

    # Get the ALIs for each year
    @year_1_alis = get_alis(@year_1)
    @year_2_alis = get_alis(@year_2)
    @year_3_alis = get_alis(@year_3)

  end

  # Process a request to load a scheduler update form. This is ajaxed
  def loader

    @asset = Asset.find_by_object_key(params[:id])
    @current_year = params[:year].to_i
    @active_year = params[:active_year]

    @actions = ACTIONS

    @fiscal_years = []
    (@year_1..@year_1 + 3).each do |yr|
      @fiscal_years << [fiscal_year(yr), yr]
    end
    @proxy = SchedulerActionProxy.new
    @proxy.set_defaults(@asset)

  end

  # Render the partial for the asset edit modal.
  def edit_asset_in_modal
    # TODO refactor with code in #loader, above.
    # #loader can possibly go away
    @asset = Asset.find_by_object_key(params[:id])
    @current_year = params[:year].to_i
    @active_year = @current_year

    @actions = ACTIONS

    @fiscal_years = []
    (current_planning_year_year..last_fiscal_year_year).each do |yr|
      @fiscal_years << [fiscal_year(yr), yr]
    end
    @proxy = SchedulerActionProxy.new
    @proxy.set_defaults(@asset)

    render partial: 'edit_asset_in_modal'
  end

  #-----------------------------------------------------------------------------
  # Render the partial for the asset edit modal.
  # from planning control
  #-----------------------------------------------------------------------------
  # def edit_asset
  #
  #   @asset = Asset.find_by_object_key(params[:id])
  #   @actions = ACTIONS
  #
  #   @fiscal_years = []
  #   (current_planning_year_year..last_fiscal_year_year).each do |yr|
  #     @fiscal_years << [fiscal_year(yr), yr]
  #   end
  #   @proxy = SchedulerActionProxy.new
  #   @proxy.set_defaults(@asset)
  #
  #   render :partial => 'edit_asset_modal_form'
  # end

  # Render the partial for the update cost modal.
  def update_cost_modal
    @capital_project = CapitalProject.where(object_key: params[:capital_project]).first
    @ali = ActivityLineItem.where(object_key: params[:ali]).first
    @active_year = @ali.capital_project.fy_year

    render :partial => 'update_cost_modal'
  end

  # Render the partial for adding a funding plan to the ALI
  def add_funding_plan_modal

    @ali = ActivityLineItem.find_by_object_key(params[:ali])
    service = EligibilityService.new
    @funding_sources = service.evaluate_organization_funding_sources @organization
    @active_year = @ali.capital_project.fy_year

    render :partial => 'add_funding_plan_modal_form'
  end

  # Process a scheduler action. This must be called using a JS action
  def scheduler_action

    proxy = SchedulerActionProxy.new(params[:scheduler_action_proxy])

    asset = Asset.find_by_object_key(proxy.object_key)

    case proxy.action_id
    when REPLACE_ACTION
      Rails.logger.debug "Updating asset #{asset.object_key}. New scheduled replacement year = #{proxy.fy_year.to_i}"
      asset.scheduled_replacement_year = proxy.fy_year.to_i if proxy.fy_year
      asset.replacement_reason_type_id = proxy.reason_id.to_i if proxy.reason_id
      asset.scheduled_replacement_cost = proxy.replace_cost.to_i if proxy.replace_cost
      asset.scheduled_replace_with_new = proxy.replace_with_new.to_i if proxy.replace_with_new
      asset.save
      #notify_user :notice, "#{asset.asset_subtype}: #{asset.asset_tag} #{asset.description} is scheduled for replacement in #{fiscal_year(proxy.year.to_i)}"

    when REHABILITATE_ACTION
      asset.scheduled_rehabilitation_year = proxy.fy_year.to_i
      asset.scheduled_replacement_year = asset.scheduled_rehabilitation_year + proxy.extend_eul_years.to_i
      asset.scheduled_rehabilitation_cost = proxy.rehab_cost.to_i
      asset.save
      #notify_user :notice, "#{asset.asset_subtype}: #{asset.asset_tag} #{asset.description} is now scheduled for replacement in #{fiscal_year(proxy.replace_fy_year.to_i)}"

    when REMOVE_FROM_SERVICE_ACTION
      asset.scheduled_rehabilitation_year = nil
      asset.scheduled_replacement_year = nil
      asset.scheduled_replacement_cost = nil
      asset.scheduled_replace_with_new = nil
      asset.scheduled_rehabilitation_cost = nil
      asset.scheduled_disposition_year = proxy.fy_year.to_i
      asset.save

    when RESET_ACTION
      asset.scheduled_rehabilitation_year = nil
      asset.scheduled_replacement_year = asset.policy_replacement_year
      asset.scheduled_disposition_year = nil
      asset.scheduled_replacement_cost = nil
      asset.scheduled_replace_with_new = nil
      asset.scheduled_rehabilitation_cost = nil
      asset.save

    end

    # Update the capital projects with this new data
    builder = CapitalProjectBuilder.new
    builder.update_asset_schedule(asset)

    # Get the ALIs for each year
    @year_1_alis = get_alis(@year_1)
    @year_2_alis = get_alis(@year_2)
    @year_3_alis = get_alis(@year_3)

  end

  # General purpose action for mamipulating ALIs in the plan. This action
  # must be called as JS
  def scheduler_ali_action

    @activity_line_item = ActivityLineItem.find_by_object_key(params[:ali])
    @project = @activity_line_item.capital_project
    @action = params[:invoke]

    case @action
    when ALI_MOVE_YEAR_ACTION, 'move_ali_to_fiscal_year'

      @fy_year = params[:year].to_i
      if @activity_line_item.present? and @fy_year > 0
        assets = @activity_line_item.assets.where(object_key: params[:targets].split(','))

        if assets.count > 25
          Delayed::Job.enqueue MoveAssetYearJob.new(@activity_line_item, @fy_year, params[:targets], current_user, params[:early_replacement_reason]), :priority => 0

          notify_user :notice, "Assets are being moved. You will be notified when the process is complete."
        else

          service = CapitalProjectBuilder.new
          assets_count = assets.count
          Rails.logger.debug "Found #{assets_count} assets to process"
          assets.each do |a|
            # Replace or Rehab?
            if @activity_line_item.rehabilitation_ali?
              a.scheduled_rehabilitation_year = @fy_year
            else
              a.scheduled_replacement_year = @fy_year
              a.update_early_replacement_reason(params[:early_replacement_reason])
            end

            a.save(:validate => false)
            a.reload
            service.update_asset_schedule(a)
            a.reload
          end

          # update the original ALI's estimated cost for its assets
          updated_ali = ActivityLineItem.find_by(id: @activity_line_item.id)
          if updated_ali.present?
            updated_ali.update_estimated_cost
            Rails.logger.debug("NEW COST::: #{updated_ali.estimated_cost}")
          end

          notify_user :notice, "Moved #{assets_count} assets to #{fiscal_year(@fy_year)}"
        end

      else
        notify_user :alert,  "Missing ALI or fy_year. Can't perform update."
      end

    when ALI_UPDATE_COST_ACTION
      @activity_line_item.anticipated_cost = params[:activity_line_item][:anticipated_cost]
      if @activity_line_item.save
        @msg = "The ALI was successfully updated."
      else
        @msg = "An error occurred while updating the ALI."
      end

    when ALI_REMOVE_ACTION
      @activity_line_item.destroy
      @msg = "The ALI was successfully removed from project #{@project.project_number}."

    when ALI_ADD_FUND_ACTION

      # Add a funding plan to this ALI
      @funding_request = FundingRequest.new

      @msg = "The ALI was successfully updated."


    when ALI_EDIT_FUND_ACTION
      @funding_request = FundingRequest.find_by(object_key: params[:funding_request])
      when ALI_REMOVE_FUND_ACTION
      @msg = "The ALI was successfully updated."
    end

    # Get the ALIs for each year
    @year_1_alis = get_alis(@year_1) if @year_1
  end

  # General purpose action for mamipulating ALIs in the plan. This action
  # must be called as JS
  def scheduler_swimlane_action
    ali = params[:ali]

    @activity_line_item = ActivityLineItem.find_by(object_key: ali)
    @project = @activity_line_item.capital_project if @activity_line_item

    # Get the ALIs for each year
    @year_1_alis = get_alis(@year_1) if @year_1

  end

  protected

  # Sets the view variables that control the filters. called before each action is invoked
  def set_view_vars

    if params[:org_id].blank?
      return
    else
      @org_id = params[:org_id].to_i
    end

    unless params[:active_year].blank?
      @active_year = params[:active_year].to_i
    end

    # This is the first year that the user can plan for
    @first_year = current_fiscal_year_year + 1
    # This is the last year of a 3 year plan
    @last_year = last_fiscal_year_year - 2
    # This is an array of years that the user can plan for
    @years = (@first_year..@last_year).to_a

    # Set the view up. Start year is the first year in the view
    @start_year = params[:start_year].blank? ? @first_year : params[:start_year].to_i
    @year_1 = @start_year
    @year_2 = @start_year + 1
    @year_3 = @start_year + 2

    # Set up the active year class var
    if @active_year.nil?
      @active_year = @year_1
    elsif @active_year < @start_year
      @active_year = @year_1
    elsif @active_year > @year_3
      @active_year = @year_3
    end

    # Add ability to page year by year
    @total_rows = @years.size
    # get the index of the start year in the array
    current_index = @years.index(@start_year)
    @row_number = current_index + 1
    if current_index == 0
      @prev_record_path = "#"
    else
      @prev_record_path = scheduler_index_path(:active_year => @active_year, :start_year => @start_year - 1, :asset_subtype_id => @asset_subtype_id, :org_id => @org_id)
    end
    if current_index == (@total_rows - 1)
      @next_record_path = "#"
    else
      @next_record_path = scheduler_index_path(:active_year => @active_year, :start_year => @start_year + 1, :asset_subtype_id => @asset_subtype_id, :org_id => @org_id)
    end
    @row_pager_remote = true

  end

  def get_alis(year)
    capital_project_ids = CapitalProject.where(:organization_id =>  @org_id)

    ActivityLineItem.where(:capital_project_id => capital_project_ids, :fy_year => year)
  end

  private

end

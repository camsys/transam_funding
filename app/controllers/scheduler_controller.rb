class SchedulerController < AbstractCapitalProjectsController

  include TransamFormatHelper

  before_filter :set_view_vars,  :only =>    [:index, :loader, :scheduler_ali_action, :scheduler_swimlane_action]

  before_action :get_activity_line_item, :only => [:scheduler_ali_action, :scheduler_swimlane_action]

  add_breadcrumb "Home", :root_path

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

  def choose_org

  end

  # Returns the list of assets that are scheduled for replacement/rehabilitation in the given
  # fiscal years.
  def index

    add_breadcrumb "Scheduler", scheduler_index_path(:start_year => @start_year)

    current_index = @years.index(@start_year)
    if current_index == 0
      @prev_record_path = "#"
    else
      @prev_record_path = scheduler_index_path(:start_year => @start_year - 1)
    end
    if current_index == (@total_rows - 1)
      @next_record_path = "#"
    else
      @next_record_path = scheduler_index_path(:start_year => @start_year + 1)
    end

    @total_projects_cost_by_year = @projects.joins(:activity_line_items).where('activity_line_items.id IN (?)', @alis.ids).group("activity_line_items.fy_year").sum(ActivityLineItem::COST_SUM_SQL_CLAUSE)

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

  # General purpose action for mamipulating ALIs in the plan. This action
  # must be called as JS
  def scheduler_ali_action

    add_breadcrumb "Scheduler", scheduler_index_path(:start_year => @start_year)

    @active_year = @start_year
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

      redirect_to :back

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
      unless params[:funding_request].blank?
        @funding_request = FundingRequest.find_by(object_key: params[:funding_request])
        @msg = "The ALI was successfully updated."
      end
    when ALI_REMOVE_FUND_ACTION
      @funding_request = FundingRequest.find_by(object_key: params[:funding_request])
      if @funding_request.destroy
        @msg = "The funding line was successfully deleted."
      else
        @msg = "There was an error deleting the funding line."
      end

      redirect_to :back
    end

    # Get the ALIs for each year
    @year_1_alis = get_alis(@year_1) if @year_1
  end

  # General purpose action for mamipulating ALIs in the plan. This action
  # must be called as JS
  def scheduler_swimlane_action

    add_breadcrumb "Scheduler", scheduler_index_path(:start_year => @start_year)
    add_breadcrumb format_as_fiscal_year(@start_year), scheduler_swimlane_action_scheduler_index_path(start_year: @start_year)
    if @activity_line_item
      add_breadcrumb @activity_line_item.to_s, scheduler_swimlane_action_scheduler_index_path(start_year: @start_year, ali: @activity_line_item.object_key)
    end

    @active_year = @start_year

    current_index = @years.index(@start_year)
    if current_index == 0
      @prev_record_path = "#"
    else
      @prev_record_path = scheduler_swimlane_action_scheduler_index_path(:start_year => @start_year - 1, sort: params[:sort])
    end
    if current_index == (@total_rows - 1)
      @next_record_path = "#"
    else
      @next_record_path = scheduler_swimlane_action_scheduler_index_path(:start_year => @start_year + 1, sort: params[:sort])
    end

    # Get the ALIs for each year
    @year_1_alis = get_alis(@year_1) if @year_1

  end

  protected

  # Sets the view variables that control the filters. called before each action is invoked
  def set_view_vars

   get_planning_years

    # Set the view up. Start year is the first year in the view
    @start_year = params[:start_year].blank? ? @first_year : params[:start_year].to_i
    @year_1 = @start_year
    @year_2 = @start_year + 1
    @year_3 = @start_year + 2

    # Add ability to page year by year
    @total_rows = @years.size
    # get the index of the start year in the array
    current_index = @years.index(@start_year)
    @row_number = current_index + 1

    get_projects

  end

  def get_alis(year)
    alis = @alis.where(:fy_year => year)

    case params[:sort]
      when 'cost'
        alis.sort_by{|a| a.cost}.reverse!
      when 'pcnt_funded'
        alis.sort_by{|a| a.pcnt_funded}.reverse!
      when 'num_assets'
        alis.sort_by{|a| a.assets.count}.reverse!
      else
        alis
    end
  end

  def get_activity_line_item
    if params[:ali]
      @activity_line_item = ActivityLineItem.joins(capital_project: :organization).find_by(capital_projects: {organization_id: @organization_list}, activity_line_items: {object_key: params[:ali]})
      if @activity_line_item
        @project = @activity_line_item.capital_project
      else
        if ActivityLineItem.joins(capital_project: :organization).find_by(capital_projects: {organization_id: current_user.user_organization_filters.system_filters.first.get_organizations.map{|x| x.id}}, activity_line_items: {object_key: params[:ali]}).nil?
          redirect_to '/404'
        else
          notify_user(:warning, 'This record is outside your filter. Change your filter if you want to access it.')
        end
      end
    end
  end

  private

end

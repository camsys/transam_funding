class FundingBucketsController < OrganizationAwareController
  # before_action :set_funding_template, only: [:show, :edit, :update, :destroy]

  add_breadcrumb "Home", :root_path

  skip_before_action :get_organization_selections,      :only => [:index, :new, :edit, :show]
  before_action :set_viewable_organizations,      :only => [:index, :new, :edit]

  before_action :set_funding_bucket, only: [:show, :edit, :update, :destroy, :edit_bucket_app, :update_bucket_app,]


  INDEX_KEY_LIST_VAR    = "funding_buckets_key_list_cache_var"


  def get_dashboard_summary
    if @organization.type_of? Grantor
      view = 'dashboards/grantor_funding_widget_table'
    else
      view = 'dashboards/transit_operator_funding_widget_table'
    end

    respond_to do |format|
      format.js { render partial: view, locals: {fy_year: params[:fy_year] }  }
    end
  end

  # GET /buckets
  def index
    authorize! :read, FundingBucket

    add_breadcrumb 'Funding Programs', funding_sources_path
    add_breadcrumb 'Templates', funding_templates_path
    add_breadcrumb 'Buckets', funding_buckets_path

    @templates =  FundingTemplate.all.pluck(:name, :id)
    @organizations = Organization.where(id: @organization_list).map{|o| [o.coded_name, o.id]}

    # Start to set up the query
    conditions  = []
    values      = []

    if params[:agency_id].present?
      @searched_agency_id =  params[:agency_id]
    end
    if params[:fy_year].present?
      @searched_fiscal_year =  params[:fy_year]
    end
    if params[:funds_filter].present?
      @funds_filter =  params[:funds_filter]
    end
    if params[:searched_template].present?
      @searched_template = params[:searched_template]
    end


    unless @searched_fiscal_year.blank?
      fiscal_year_filter = @searched_fiscal_year.to_i
      conditions << 'fy_year = ?'
      values << fiscal_year_filter
    end

    unless @searched_template.nil?
      funding_template_id = @searched_template.to_i
      conditions << 'funding_template_id = ?'
      values << funding_template_id
    end

    if @funds_filter == 'funds_available'
      conditions << 'budget_amount > budget_committed'
    elsif @funds_filter == 'zero_balance'
      conditions << 'budget_amount = budget_committed'
    elsif @funds_filter == 'funds_overcommitted'
      conditions << 'budget_amount < budget_committed'
    end

    conditions << 'funding_buckets.active = true'


    @buckets = FundingBucket.active.where(conditions.join(' AND '), *values)

    unless can? :manage, FundingTemplate
      @buckets = @buckets.where(contributor_id: (current_user.organizations.ids & @organization_list))
    end

    unless @searched_agency_id.blank?
      @buckets = @buckets.state_owned(@searched_agency_id) + @buckets.agency_owned(@searched_agency_id)
    end

    # cache the set of object keys in case we need them later
    cache_list(@buckets, INDEX_KEY_LIST_VAR)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @buckets }
    end
  end

  # GET /buckets/1
  def show


    # users in super manager role who can supervise/see all organizations ad all funding
    if can? :manage, FundingBucket
      set_viewable_organizations

      add_breadcrumb @funding_bucket.funding_template.funding_source.name, funding_source_path(@funding_bucket.funding_template.funding_source)
      add_breadcrumb @funding_bucket.funding_template.name, funding_template_path(@funding_bucket.funding_template)
    else
      get_organization_selections

      add_breadcrumb 'Funding Programs', funding_sources_path
      add_breadcrumb 'My Funds', my_funds_funding_buckets_path
    end

    authorize! :read, @funding_bucket

    add_breadcrumb @funding_bucket.to_s, funding_bucket_path(@funding_bucket)

    @funding_template = @funding_bucket.funding_template

  end

  # GET /buckets/new
  def new
    authorize! :create, FundingBucket

    add_breadcrumb 'Funding Programs', funding_sources_path
    add_breadcrumb 'Templates', funding_templates_path
    add_breadcrumb 'Buckets', funding_buckets_path
    add_breadcrumb 'New', new_funding_bucket_path

    if @bucket_proxy.present?
      @bucket_proxy = @bucket_proxy
    else
      @bucket_proxy = FundingBucketProxy.new
      @bucket_proxy.set_defaults
    end
    if @programs.present?
      @programs = @programs
    else
      @programs = FundingSource.all
    end
    if @templates.present?
      @templates = @templates
    elsif params[:funding_source_id]
      @bucket_proxy.program_id = params[:funding_source_id]
      @templates = FundingTemplate.where(funding_source_id: @bucket_proxy.program_id).pluck(:id, :name)
    else
      @templates = []
    end
    if @template_organizations.present?
      @template_organizations = @template_organizations
    elsif params[:funding_template_id]
      @bucket_proxy.template_id = params[:funding_template_id]
      @template_organizations = find_organizations(@bucket_proxy.template_id)

      @bucket_proxy.fiscal_year_range_start = params[:fiscal_year_range_start].to_i
      @bucket_proxy.fiscal_year_range_end = params[:fiscal_year_range_end].to_i
      @bucket_proxy.name = params[:name]
      @bucket_proxy.total_amount = params[:total_amount]
      program = FundingSource.find_by(id: @bucket_proxy.program_id)
      @fiscal_years = program.find_all_valid_fiscal_years
    else
      @template_organizations = []
      @fiscal_years = []
    end
    if params[:owner_id]
      @bucket_proxy.owner_id = params[:owner_id]
    end
  end

  def new_bucket_app

    authorize! :new_bucket_app, FundingBucket

    add_breadcrumb 'Funding Programs', funding_sources_path
    add_breadcrumb 'My Funds', my_funds_funding_buckets_path
    add_breadcrumb 'New Fund', new_bucket_app_funding_buckets_path

    @funding_bucket = FundingBucket.new
  end

  # GET /buckets/1/edit
  def edit
    authorize! :update, @funding_bucket

  end

  def edit_bucket_app

    authorize! :edit_bucket_app, @funding_bucket

    add_breadcrumb 'Funding Programs', funding_sources_path
    add_breadcrumb 'My Funds', my_funds_funding_buckets_path
    add_breadcrumb @funding_bucket.to_s, funding_bucket_path(@funding_bucket)
    add_breadcrumb 'Edit Fund', edit_bucket_app_funding_bucket_path(@funding_bucket)

  end

  # POST /buckets
  def create
    authorize! :read, FundingBucket

    bucket_proxy = FundingBucketProxy.new(bucket_proxy_params)
    @bucket_proxy = bucket_proxy

    all_orgs_for_template = find_organizations(bucket_proxy.template_id)
    organizations_with_budgets= []

    all_orgs_for_template.each { |org|
      unless org[0] < 0
        unless params["agency_budget_id_#{org[0]}"].blank?
          organizations_with_budgets << org[0].to_s
        end
      end
    }

    @existing_buckets = FundingBucket.find_existing_buckets_from_proxy(bucket_proxy.template_id, bucket_proxy.fiscal_year_range_start, bucket_proxy.fiscal_year_range_end, bucket_proxy.owner_id, organizations_with_budgets, bucket_proxy.name)

    if @existing_buckets.length > 0 && (bucket_proxy.create_conflict_option.blank?)
      @create_conflict = true
    elsif @existing_buckets.length > 0 && (bucket_proxy.create_conflict_option == 'Cancel')
      redirect_to funding_buckets_path, notice: 'Bucket creation cancelled because of conflict.'
    elsif @existing_buckets.length > 0
      create_new_buckets(bucket_proxy, @existing_buckets, bucket_proxy.create_conflict_option)
      unless @bucket_proxy.return_to_bucket_index == 'false'
        redirect_to funding_buckets_path, notice: 'Buckets successfully created.'
      else
        redirect_to new_funding_bucket_path(program_id: @bucket_proxy.program_id, funding_template_id: @bucket_proxy.template_id, owner_id: @bucket_proxy.owner_id, fiscal_year_range_start: @bucket_proxy.fiscal_year_range_start, fiscal_year_range_end: @bucket_proxy.fiscal_year_range_end, name: @bucket_proxy.name, total_amount: @bucket_proxy.total_amount  ), notice: 'Buckets successfully created.'
      end
    else
      create_new_buckets(bucket_proxy)
      unless @bucket_proxy.return_to_bucket_index == 'false'
        redirect_to funding_buckets_path, notice: 'Buckets successfully created.'
      else
        redirect_to new_funding_bucket_path(funding_source_id: @bucket_proxy.program_id, funding_template_id: @bucket_proxy.template_id, owner_id: @bucket_proxy.owner_id, fiscal_year_range_start: @bucket_proxy.fiscal_year_range_start, fiscal_year_range_end: @bucket_proxy.fiscal_year_range_end, name: @bucket_proxy.name, total_amount: @bucket_proxy.total_amount  ), notice: 'Buckets successfully created.'
      end
    end

  end

  def create_bucket_app
    authorize! :new_bucket_app, FundingBucket

    @funding_bucket = FundingBucket.new(bucket_params)
    @funding_bucket.creator = current_user
    @funding_bucket.updator = current_user

    if @organization_list.count == 1
      @funding_bucket.owner_id = @organization_list.first
    end

    @funding_bucket.generate_unique_name() if @funding_bucket.name.blank?

    respond_to do |format|
      if @funding_bucket.save
        notify_user(:notice, "The fund was successfully saved.")
        format.html { redirect_to my_funds_funding_buckets_path }
        format.json { render action: 'show', status: :created, location: @funding_bucket }
      else
        format.html { render action: 'new_grant' }
        format.json { render json: @funding_bucket.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /buckets/1
  def update
    authorize! :update, @funding_bucket

    respond_to do |format|
      if @funding_bucket.update(bucket_params)
        notify_user(:notice, "The bucket was successfully updated.")
        format.html { redirect_back(fallback_location: root_path) }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @funding_bucket.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_bucket_app

    authorize! :edit_bucket_app, @funding_bucket

    respond_to do |format|
      if @funding_bucket.update(bucket_params)
        notify_user(:notice, "The fund was successfully updated.")
        format.html { redirect_to my_funds_funding_buckets_path }
        format.json { head :no_content }
      else
        format.html { render action: 'edit_bucket_app' }
        format.json { render json: @funding_bucket.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /buckets/1
  def destroy
    if @funding_bucket.deleteable?
      if @funding_bucket.destroy
        notify_user(:notice, "The fund was successfully removed.")
        respond_to do |format|
          format.html {
            # check where to redirect to
            if URI(request.referer || '').path.include? "funding_buckets/#{@funding_bucket.object_key}"
              if current_user.organization_ids.include? @funding_bucket.owner_id
                redirect_to my_funds_funding_buckets_path
              else
                redirect_to funding_buckets_path
              end
            else
              redirect_back(fallback_location: root_path)
            end
          }
          format.json { head :no_content }
        end
      end
    end
  end

  def find_organizations_from_template_id
    template_id = params[:template_id]
    if params[:target_org]
      result = find_organizations(template_id, true)
    else
      result = find_organizations(template_id)
    end

    respond_to do |format|
      format.json { render json: result.to_json }
    end
  end

  def find_contributor_organizations_from_template_id
    template_id = params[:template_id]
    result = find_contributor_organizations(template_id)
    respond_to do |format|
      format.json { render json: result.to_json }
    end
  end

  def find_configuration_options_from_template_id
    template_id = params[:template_id]
    result = FundingTemplate.find_by(id: template_id)

    respond_to do |format|
      format.json { render json: result.to_json }
    end
  end

  def find_templates_from_program_id
    program_id = params[:program_id]
    if can? :manage, FundingTemplate
      result = FundingTemplate.where(funding_source_id: program_id).pluck(:id, :name)
    else
      result = FundingTemplate.joins(:funding_templates_contributor_organizations).where(funding_source_id: program_id, funding_templates_contributor_organizations: {organization_id: (current_user.organizations.ids & @organization_list)}).pluck(:id, :name)
    end

    respond_to do |format|
      format.json { render json: result.to_json }
    end
  end

  def find_existing_buckets_for_create
    result = FundingBucket.find_existing_buckets_from_proxy(params[:template_id], params[:start_year].to_i, params[:end_year].to_i, params[:owner_id].to_i, params[:specific_organizations_with_budgets], params[:name])

    msg = "#{result.length} of the Buckets you are creating already exist. Do you want to update these Buckets' budget, ignore these Buckets, or cancel this action?"

    respond_to do |format|
      format.json { render json: {:result_count => result.length, :new_html => (render_to_string :partial => 'form_modal', :formats => [:html], :locals => {:result => result, :msg => msg, :action => 'create'}) }}
    end
  end

  def find_number_of_missing_buckets_for_update

      existing_buckets = FundingBucket.find_existing_buckets_from_proxy(params[:template_id], params[:start_year], params[:end_year], params[:owner_id], nil, params[:name]).pluck(:fy_year, :owner_id)
      expected_buckets = find_expected_buckets(params[:template_id], params[:start_year].to_i, params[:end_year].to_i, params[:owner_id].to_i, params[:specific_organizations_with_budgets])
      not_created_buckets = expected_buckets - existing_buckets
      template = FundingTemplate.find_by(id: params[:template_id])
      result = []
      not_created_buckets.each do |b|
        result << FundingBucket.new(funding_template: template, fy_year: b[0], owner_id: b[1])
      end

      msg = "#{result.length} Buckets you are updating do not yet exist. Do you want to create these Buckets, ignore these Buckets, or cancel this action?"

      respond_to do |format|
        format.json { render json: {:result_count => result.length, :new_html => (render_to_string :partial => 'form_modal', :formats => [:html], :locals => {:result => result, :msg => msg, :action => 'update'}) }}
      end
  end

  def find_expected_escalation_percent
    program_id = params[:program_id]
    result = FundingSource.find_by(id: program_id).inflation_rate

    respond_to do |format|
      format.json { render json: result.to_json }
    end
  end

  def find_expected_match_percent
    bucket_name = params[:bucket_name]
    if bucket_name.present?
      bucket = FundingBucket.find_by(name: bucket_name)

      bucket.funding_template.match_required.nil? ?
          match_percent = bucket.funding_source.match_required :
          match_percent = bucket.funding_template.match_required


      result = {bucket_percent: match_percent, bucket_budget_remaining: bucket.budget_remaining}
    end

    respond_to do |format|
      format.json { render json: result.to_json }
    end
  end

  protected

  def find_organizations(template_id, target_org = false)
    # if target org false return possible owners
    # if target org true, return eligibilty orgs for buckets not yet created
    result = []

    template = FundingTemplate.find_by(id: template_id)
    if template.owner == FundingOrganizationType.find_by(code: 'grantor') && !target_org
      grantors = template.organizations.where(id: @organization_list, organization_type: OrganizationType.find_by(class_name: 'Grantor'))
      grantors.each { |g|
        result << [g.id, g.coded_name]
      }
    else
      orgs = template.organizations.where(id: @organization_list, organization_type: OrganizationType.find_by(class_name: 'TransitOperator'))
      organizations = []
      if orgs.length > 0
        orgs.each { |o|
          item = [o.id, o.coded_name]
          organizations << item
        }
      end

      if target_org
        organizations.select{|o| !(template.funding_buckets.where('target_organization_id IS NOT NULL').pluck(:target_organization_id).include? o[0])}
      end

      result = organizations
    end

    result
  end

  def find_contributor_organizations(template_id)
    # if target org false return possible owners
    # if target org true, return eligibilty orgs for buckets not yet created
    result = []

    template = FundingTemplate.find_by(id: template_id)
    if template.contributor == FundingOrganizationType.find_by(code: 'grantor')
      grantors = template.contributor_organizations.where(id: @organization_list, organization_type: OrganizationType.find_by(class_name: 'Grantor'))
      grantors.each { |g|
        result << [g.id, g.coded_name]
      }
    else
      orgs = template.contributor_organizations.where(id: @organization_list, organization_type: OrganizationType.find_by(class_name: 'TransitOperator'))
      organizations = []
      if orgs.length > 0
        orgs.each { |o|
          item = [o.id, o.coded_name]
          organizations << item
        }
      end

      result = organizations
    end

    puts result.inspect

    result
  end

  def create_new_buckets(bucket_proxy, existing_buckets=nil, create_conflict_option=nil)

    unless bucket_proxy.owner_id.to_i <= 0
      bucket = new_bucket_from_proxy(bucket_proxy)
      create_single_organization_buckets(bucket, bucket_proxy, existing_buckets, create_conflict_option, 'Create')
    else
      organizations = find_organizations(bucket_proxy.template_id)


      organizations.each { |org|
        unless org[0] < 0 || params["agency_budget_id_#{org[0]}"].blank?
          bucket = new_bucket_from_proxy(bucket_proxy, org[0])
          bucket.budget_amount = params["agency_budget_id_#{org[0]}".parameterize.underscore.to_sym].to_d
          # bucket_proxy inflation percentage could be modified the same way
          create_single_organization_buckets(bucket, bucket_proxy, existing_buckets, create_conflict_option, 'Create', org[0],)
        end
      }

    end
  end

  def update_buckets(bucket_proxy, existing_buckets=nil, update_conflict_option=nil )

    unless bucket_proxy.owner_id.to_i <= 0
      bucket = new_bucket_from_proxy(bucket_proxy)
      create_single_organization_buckets(bucket, bucket_proxy, existing_buckets, 'Update',  update_conflict_option)
    else
      bucket = new_bucket_from_proxy(bucket_proxy)
      organizations = find_organizations(bucket_proxy.template_id)

      organizations.each { |org|
        unless org[0] < 0
          unless params["agency_budget_id_#{org[0]}"].blank?
            bucket = new_bucket_from_proxy(bucket_proxy, org[0])
            bucket.budget_amount = params["agency_budget_id_#{org[0]}".parameterize.underscore.to_sym].to_d
            # bucket_proxy inflation percentage could be modified the same way
            create_single_organization_buckets(bucket, bucket_proxy, existing_buckets, 'Update', update_conflict_option, org[0],)
          end
        end
      }

    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_funding_bucket
    @funding_bucket = FundingBucket.find_by(object_key: params[:id])

    if @funding_bucket.nil?
      redirect_to '/404'
    end
  end

  def set_viewable_organizations
    @viewable_organizations = current_user.viewable_organizations.where.not(organization_type: OrganizationType.find_by(class_name: 'PlanningPartner')).pluck(:id)

    get_organization_selections
  end

  def bucket_params
    params.require(:funding_bucket).permit(FundingBucket.allowable_params)
  end

  # Only allow a trusted parameter "white list" through.
  def bucket_proxy_params
    params.require(:funding_bucket_proxy).permit(FundingBucketProxy.allowable_params)
  end

  def new_bucket_from_proxy(bucket_proxy, agency_id=nil)
    bucket = FundingBucket.new
    bucket.set_values_from_proxy(bucket_proxy, agency_id)
    bucket.creator = current_user
    bucket.updator = current_user
    bucket
  end

  def create_single_organization_buckets(bucket, bucket_proxy, existing_buckets, create_conflict_option, update_conflict_option, agency_id=nil)

    unless bucket_proxy.fiscal_year_range_start == bucket_proxy.fiscal_year_range_end
      i = bucket_proxy.fiscal_year_range_start.to_i + 1
      next_year_budget = bucket.budget_amount
      inflation_percentage = bucket_proxy.inflation_percentage.blank? ? 0 : bucket_proxy.inflation_percentage.to_d/100

      existing_bucket = bucket_exists(existing_buckets, bucket)
      if (!existing_bucket.nil? && (create_conflict_option == 'Ignore')) || (existing_bucket.nil? && update_conflict_option == 'Ignore')
          # DO NOTHING
      elsif !existing_bucket.nil? && create_conflict_option == 'Replace'
        existing_bucket.budget_amount = bucket.budget_amount
        existing_bucket.updator = current_user
        existing_bucket.save
      elsif update_conflict_option == 'Create'
        bucket.save
      end

      while i <= bucket_proxy.fiscal_year_range_end.to_i
        next_year_bucket = new_bucket_from_proxy(bucket_proxy, agency_id)
        next_year_bucket.fy_year = i
        next_year_bucket.name = "#{next_year_bucket.funding_template.name}-#{next_year_bucket.owner.short_name}-#{next_year_bucket.fiscal_year_for_name(i)}"
        if next_year_bucket.target_organization_id.to_i > 0
         next_year_bucket.name = "#{next_year_bucket.name}-#{next_year_bucket.target_organization.short_name}"
        end

        unless bucket_proxy.inflation_percentage.blank?
          next_year_budget = next_year_budget + (inflation_percentage * next_year_budget)
        end
        next_year_bucket.budget_amount = next_year_budget


        existing_bucket = bucket_exists(existing_buckets, next_year_bucket)
        if (!existing_bucket.nil? && (create_conflict_option == 'Ignore')) || (existing_bucket.nil? && update_conflict_option == 'Ignore')
          #   DO NOTHING
        elsif !existing_bucket.nil? && create_conflict_option == 'Replace'
          existing_bucket.budget_amount = next_year_bucket.budget_amount
          existing_bucket.updator = current_user
          existing_bucket.save
        elsif update_conflict_option == 'Create'
          next_year_bucket.save
        end

        i += 1
      end

    else
      existing_bucket = bucket_exists(existing_buckets, bucket)
      if (!existing_bucket.nil? && (create_conflict_option == 'Ignore')) || (existing_bucket.nil? && update_conflict_option == 'Ignore')
        #   DO NOTHING
      elsif !existing_bucket.nil? && create_conflict_option == 'Replace'
        existing_bucket.budget_amount = bucket.budget_amount
        existing_bucket.updator = current_user
        if bucket_proxy.name.blank?
          existing_bucket.name = "#{existing_bucket.funding_template.name}-#{existing_bucket.owner.short_name}-#{existing_bucket.fiscal_year_for_name(existing_bucket.fy_year)}"
        else
          existing_bucket.name = bucket_proxy.name
        end
        existing_bucket.save
      else
        puts bucket.inspect
        bucket.save!
      end
    end
  end

  def bucket_exists existing_buckets, bucket
    unless existing_buckets.nil?
      buckets = existing_buckets.find {|eb|
        eb.funding_template == bucket.funding_template && eb.fy_year == bucket.fy_year && eb.owner == bucket.owner && eb.name == bucket.name
      }
      return buckets
    end

    return nil
  end

  def find_expected_bucket_count_from_bucket_proxy bucket_proxy
    orgs = find_organizations(bucket_proxy.template_id)
    orgs_with_budgets =  []
    orgs.each { |org|
      unless org[0] < 0
        unless params["agency_budget_id_#{org[0]}"].blank?
          orgs_with_budgets << org[0]
        end
      end
    }

    find_expected_bucket_count(bucket_proxy.template_id, bucket_proxy.fiscal_year_range_start.to_i, bucket_proxy.fiscal_year_range_end.to_i, bucket_proxy.owner_id.to_i, orgs_with_budgets)
  end

  def find_expected_bucket_count template_id, fiscal_year_range_start, fiscal_year_range_end, owner_id, orgs_with_budgets

    number_of_organizations = 1
    if owner_id <= 0
      number_of_organizations = 0
      organizations = find_organizations(template_id)
      organizations.each {|o|
        if (orgs_with_budgets.length == 0 ||  orgs_with_budgets.include?(o[0]))
          number_of_organizations+=1
        end
      }
    end

    (1+fiscal_year_range_end - fiscal_year_range_start) * number_of_organizations

  end

  def find_expected_buckets template_id, fiscal_year_range_start, fiscal_year_range_end, owner_id, orgs_with_budgets
    fiscal_years = (fiscal_year_range_start..fiscal_year_range_end).to_a

    orgs = [owner_id]
    if owner_id <= 0
      orgs = []
      organizations = find_organizations(template_id)
      organizations.each {|o|
        if !orgs_with_budgets.nil?
          if orgs_with_budgets.length == 0 || orgs_with_budgets.include?(o[0].to_s)
            orgs << o[0]
          end
        else
          orgs << o[0]
        end
      }
    end

    fiscal_years.product(orgs)
  end
end

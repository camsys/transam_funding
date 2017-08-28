class BondRequestsController < OrganizationAwareController
  before_action :set_bond_request, only: [:show, :edit, :update, :destroy, :fire_workflow_event]

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Bond Requests", :bond_requests_path

  INDEX_KEY_LIST_VAR    = "bond_request_key_list_cache_var"

  # GET /bond_requests
  def index

    # Start to set up the query
    conditions  = []
    values      = []

    conditions << 'organization_id IN (?)'
    values << @organization_list

    if params[:state_filter]
      @request_state = params[:state_filter]
      conditions << 'state IN (?)'
      values << @request_state
    else
      @request_state = []
    end

    @submitted_at = params[:submitted_at_filter]
    if @submitted_at
      conditions << 'DATE(submitted_at) = ?'
      values << @submitted_at
    end

    #puts conditions.inspect
    #puts values.inspect
    @bond_requests = BondRequest.where(conditions.join(' AND '), *values)

    # cache the set of object keys in case we need them later
    cache_list(@bond_requests, INDEX_KEY_LIST_VAR)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @bond_requests }
    end

  end

  # GET /bond_requests/1
  def show
    add_breadcrumb @bond_request.to_s, bond_request_path(@bond_request)

    # get the @prev_record_path and @next_record_path view vars
    get_next_and_prev_object_keys(@bond_request, INDEX_KEY_LIST_VAR)
    @prev_record_path = @prev_record_key.nil? ? "#" : funding_template_path(@prev_record_key)
    @next_record_path = @next_record_key.nil? ? "#" : funding_template_path(@next_record_key)

  end

  # GET /bond_requests/new
  def new
    add_breadcrumb 'New', new_bond_request_path

    @bond_request = BondRequest.new
  end

  # GET /bond_requests/1/edit
  def edit
    add_breadcrumb @bond_request.to_s, bond_request_path(@bond_request)
    add_breadcrumb 'Edit', edit_bond_request_path(@bond_request)
  end

  # POST /bond_requests
  def create
    @bond_request = BondRequest.new(bond_request_params)

    if @bond_request.save
      redirect_to @bond_request, notice: 'Bond request was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /bond_requests/1
  def update
    if @bond_request.update(bond_request_params)
      redirect_to @bond_request, notice: 'Bond request was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /bond_requests/1
  def destroy
    @bond_request.destroy
    redirect_to bond_requests_url, notice: 'Bond request was successfully destroyed.'
  end

  def new_workflow_event

    @event_name = params[:event]
    @workflow_event_proxy = BondRequestWorkflowEventProxy.new
    @workflow_event_proxy.request_object_keys = params[:targets]
    @workflow_event_proxy.event_name = @event_name

  end

  def fire_workflow_event

    # Check that this is a valid event name for the state machines
    if params[:event]
      event_name = params[:event]
    else
      event_proxy = BondRequestWorkflowEventProxy.new(bond_request_workflow_params)
      event_name = event_proxy.event_name
    end

    perform_workflow_update @bond_request, event_name, event_proxy

    redirect_to :back

  end


  def fire_workflow_events

    if params[:event]
      event_name = params[:event]
    else
      event_proxy = BondRequestWorkflowEventProxy.new(bond_request_workflow_params)
      event_name = event_proxy.event_name
    end

    Rails.logger.debug "fire_workflow_events event_name: #{event_name}"

    # Check that this is a valid event name for the state machine
    if params[:targets].present?
      requests = BondRequest.where(:object_key => params[:targets].split(','))
    else
      requests = BondRequest.where(:object_key => event_proxy.request_object_keys)
    end
    # Process each order sequentially
    requests.each do |bond_request|
      # use the common controller method to do the work
      perform_workflow_update bond_request, event_name, event_proxy
    end

    redirect_to :back
  end

  def perform_workflow_update bond_request, event_name, event_proxy
    if BondRequest.event_names.include? event_name
      if bond_request.fire_state_event(event_name)
        event = WorkflowEvent.new
        event.creator = current_user
        event.accountable = bond_request
        event.event_type = event_name
        event.save

        if event_proxy
          if event_name == 'reject'
            bond_request.update(rejection: event_proxy.rejection)
          elsif event_name == 'authorize'
            bond_request.update(act_num: event_proxy.act_num, fy_year: event_proxy.fy_year, pt_num: event_proxy.pt_num)
          end
        end
      else
        notify_user(:alert, "Could not #{event_name.humanize} task #{bond_request}")
      end
    else
      notify_user(:alert, "#{event_name} is not a valid event for a bond request")
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bond_request
      @bond_request = BondRequest.find_by(object_key: params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def bond_request_params
      params.require(:bond_request).permit(BondRequest.allowable_params)
    end

    def bond_request_workflow_params
      params.require(:bond_request_workflow_event_proxy).permit(BondRequestWorkflowEventProxy.allowable_params)
    end

end


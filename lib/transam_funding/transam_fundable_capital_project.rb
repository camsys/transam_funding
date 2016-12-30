module TransamFundableCapitalProject
  #------------------------------------------------------------------------------
  #
  # Plannable
  #
  # Injects methods and associations for associating capital projects and ALIs with funding
  #
  #
  #------------------------------------------------------------------------------
  extend ActiveSupport::Concern

  included do

    # ----------------------------------------------------
    # Call Backs
    # ----------------------------------------------------


    # ----------------------------------------------------
    # Associations
    # ----------------------------------------------------

    # ----------------------------------------------------
    # Validations
    # ----------------------------------------------------


  end

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  module ClassMethods

    def self.total_funds
      self.joins(activity_line_items: :funding_plans).sum("funding_plans.amount")
    end

    def self.total_federal_funds
      0

      #TODO: revisit when funding_source is enabled, refer to instance method .federal_funds
    end

    def self.total_state_funds
      0

      #TODO: revisit when funding_source is enabled, refer to instance method .state_funds
    end

    def self.total_local_funds
      0

      #TODO: revisit when funding_source is enabled, refer to instance method .local_funds
    end

  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  # Render the project as a JSON object -- overrides the default json encoding
  def as_json(options={})
    {
        object_key: object_key,
        agency: organization.try(:to_s),
        fy_year: fiscal_year,
        project_number: project_number,
        scope: team_ali_code.try(:scope),
        is_emergency: emergency?,
        is_sogr: sogr?,
        is_notional: notional?,
        is_multi_year: multi_year?,
        type: capital_project_type.try(:code),
        title: title,
        total_cost: total_cost,
        state_funds: state_funds,
        local_funds: local_funds,
        federal_funds: federal_funds,
        total_funds: total_funds,
        has_early_replacement_assets: has_early_replacement_assets?
    }
  end

  def state_funds
    0

    # TODO: re-enable following line when funding_source is enabled
    #activity_line_items.joins(funding_plans: :funding_source).sum("funding_plans.amount * (funding_sources.state_match_required / 100.0)")
  end

  def federal_funds
    0

    # TODO: re-enable following line when funding_source is enabled
    #activity_line_items.joins(funding_plans: :funding_source).sum("funding_plans.amount * (funding_sources.federal_match_required / 100.0)")
  end

  def local_funds
    0

    # TODO: re-enable following line when funding_source is enabled
    #activity_line_items.joins(funding_plans: :funding_source).sum("funding_plans.amount * (funding_sources.local_match_required / 100.0)")
  end

  def total_funds
    0
  end

  # Returns the amount that is not yet funded
  def funding_difference
    total_cost - total_funds
  end


end

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
      self.total_federal_funds + self.total_state_funds + self.total_local_funds
    end

    def self.total_federal_funds
      self.joins(activity_line_items: :funding_requests).sum("funding_requests.federal_amount")
    end

    def self.total_state_funds
      self.joins(activity_line_items: :funding_requests).sum("funding_requests.state_amount")
    end

    def self.total_local_funds
      self.joins(activity_line_items: :funding_requests).sum("funding_requests.local_amount")
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

  def federal_funds
    activity_line_items.joins(:funding_requests).sum("funding_requests.federal_amount")
  end

  def state_funds
    activity_line_items.joins(:funding_requests).sum("funding_requests.state_amount")
  end

  def local_funds
    activity_line_items.joins(:funding_requests).sum("funding_requests.local_amount")
  end

  def total_funds
    federal_funds + state_funds + local_funds
  end

  # Returns the amount that is not yet funded
  def funding_difference
    total_cost - total_funds
  end


end

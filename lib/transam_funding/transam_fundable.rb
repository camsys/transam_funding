module TransamFundable
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

    # Has 0 or more funding plans -- A funding plan identifies the sources and amounts
    # of funds that will be used to fund the ALI
    #has_many    :funding_plans,     :dependent => :destroy

    # Has 0 or more funding requests, These will be removed if the project is removed.
    has_many    :funding_requests,  :dependent => :destroy

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

  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  # Returns the total amount of funding planned for this ali
  def total_funds
    federal_funds + state_funds + local_funds
  end

  def funds_required
    cost - total_funds
  end

  # Returns the total value of federal funds requested
  def federal_funds
    funding_requests.sum(:federal_amount)
  end

  # Returns the total value of state funds requested
  def state_funds
    funding_requests.sum(:state_amount)
  end

  # Returns the total value of local funds requested
  def local_funds
    funding_requests.sum(:local_amount)
  end

  def federal_percentage
    100.0 * (federal_funds / total_funds) if total_funds.to_i > 0
  end
  def state_percentage
    100.0 * (state_funds / total_funds) if total_funds.to_i > 0
  end
  def local_percentage
    100.0 * (local_funds / total_funds) if total_funds.to_i > 0
  end

end

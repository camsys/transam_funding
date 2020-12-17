module FundableFundingSourcesController
  #------------------------------------------------------------------------------
  #
  # Accounting Methods for AssetsController
  #
  # Injects methods and associations for managing depreciable assets into
  # Assets controller
  #
  #
  #------------------------------------------------------------------------------
  extend ActiveSupport::Concern

  included do

    #skip_before_action :check_filter,     :only => [:authorizations]

    before_action :set_new_funding_template, only: [:show]

    # ----------------------------------------------------
    # Associations
    # ----------------------------------------------------

    # ----------------------------------------------------
    # Validations
    # ----------------------------------------------------

  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  private

  def set_new_funding_template
    @funding_template = FundingTemplate.new(funding_source_id: @funding_source.id)
  end


end

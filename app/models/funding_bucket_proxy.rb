class FundingBucketProxy < Proxy

  #-----------------------------------------------------------------------------
  # Attributes
  #-----------------------------------------------------------------------------

  # has_many :bucket_agency_allocation

  # key for the asset being manipulated
  attr_accessor   :object_key
  attr_accessor   :create_option
  attr_accessor   :create_conflict_option
  attr_accessor   :update_conflict_option
  attr_accessor   :program_id
  attr_accessor   :template_id
  attr_accessor   :owner_id
  attr_accessor   :contributor_id
  attr_accessor   :fiscal_year_range_start
  attr_accessor   :fiscal_year_range_end
  attr_accessor   :name
  attr_accessor   :total_amount
  # attr_accessor   :bucket_type_id
  attr_accessor   :inflation_percentage
  attr_accessor   :description
  attr_accessor   :return_to_bucket_index
  attr_accessor   :target_organization_id
  attr_accessor   :external_id



  #-----------------------------------------------------------------------------
  # Validations
  #-----------------------------------------------------------------------------

  #-----------------------------------------------------------------------------
  # Constants
  #-----------------------------------------------------------------------------

  # List of allowable form param hash keys
  FORM_PARAMS = [
      :object_key,
      :create_option,
      :create_conflict_option,
      :update_conflict_option,
      :program_id,
      :template_id,
      :owner_id,
      :contributor_id,
      :fiscal_year_range_start,
      :fiscal_year_range_end,
      :name,
      :total_amount,
      # :bucket_type_id,
      :inflation_percentage,
      :description,
      :return_to_bucket_index,
      :target_organization_id,
      :external_id
  ]

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  def self.allowable_params
    FORM_PARAMS
  end

  def set_defaults
  end

  #-----------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #-----------------------------------------------------------------------------

  #-----------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #-----------------------------------------------------------------------------
  protected

  def initialize(attrs = {})
    super
    attrs.each do |k, v|
      self.send "#{k}=", v
    end
  end

end
#-------------------------------------------------------------------------------
# BondRequestWorkflowEventProxy
#
# Proxy class for gathering workflow event info
#
#-------------------------------------------------------------------------------
class BondRequestWorkflowEventProxy < Proxy

  #-----------------------------------------------------------------------------
  # Attributes
  #-----------------------------------------------------------------------------
  attr_accessor     :request_object_keys
  attr_accessor     :event_name
  attr_accessor     :rejection

  attr_accessor     :fy_year
  attr_accessor     :act_num
  attr_accessor     :pt_num
  attr_accessor     :page_num
  attr_accessor     :grantee_code
  attr_accessor     :item_num
  attr_accessor     :line_num

  #-----------------------------------------------------------------------------
  # Validations
  #-----------------------------------------------------------------------------
  validates :request_object_key,               :presence => true
  validates :event_name,             :presence => true

  #-----------------------------------------------------------------------------
  # Constants
  #-----------------------------------------------------------------------------

  # List of allowable form param hash keys
  FORM_PARAMS = [
    :request_object_keys,
    :event_name,
    :rejection,
    :fy_year,
    :line_num,
    :act_num,
    :pt_num,
    :grantee_code,
    :page_num,
    :item_num
  ]

  #-----------------------------------------------------------------------------
  #
  # Class Methods
  #
  #-----------------------------------------------------------------------------

  def self.allowable_params
    FORM_PARAMS
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
    self.request_object_keys ||= []
  end

end

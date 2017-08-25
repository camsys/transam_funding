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
  attr_accessor     :act_num
  attr_accessor     :fy_year
  attr_accessor     :pt_num

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
    :act_num,
    :fy_year,
    :pt_num
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

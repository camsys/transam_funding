class BondRequest < ActiveRecord::Base

  # Include the object key mixin
  include TransamObjectKey

  include TransamWorkflow

  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize  :set_defaults


  belongs_to :organization
  belongs_to :funding_template

  #------------------------------------------------------------------------------
  #
  # State Machine
  #
  # Used to track the state of a form through the approval process
  #
  #------------------------------------------------------------------------------
  state_machine :state, :initial => :pending do

    #-------------------------------
    # List of allowable states
    #-------------------------------

    state :pending

    state :rejected

    state :submitted

    state :authorized

    state :not_authorized

    #---------------------------------------------------------------------------
    # List of allowable events. Events transition a Form from one state to another
    #---------------------------------------------------------------------------

    # submit a form for approval. This will place the form in the approvers queue.
    event :reject do

      transition [:pending] => :rejected

    end

    # An approver is returning the form for additional information or changes
    event :submit do

      transition [:pending] => :submitted

    end

    # An approver is approving a form
    event :authorize do

      transition [:submitted] => :authorized

    end

    # An approver is returning the form for additional information or changes
    event :not_authorize do

      transition [:submitted] => :not_authorized

    end

    # Callbacks
    before_transition do |form, transition|
      Rails.logger.debug "Transitioning #{form} from #{transition.from_name} to #{transition.to_name} using #{transition.event}"
    end
  end


  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------

  validates :organization,       :presence => true
  validates :title,              :presence => true
  validates :description,        :presence => true
  validates :justification,      :presence => true
  validates :amount,             :presence => true, :numericality => {:greater_than => 0}
  validates :federal_pcnt,       :presence => true, :numericality => {:greater_than_or_equal_to => 0}
  validates :state_pcnt,         :presence => true, :numericality => {:greater_than_or_equal_to => 0}

  #------------------------------------------------------------------------------
  #
  # Scopes
  #
  #------------------------------------------------------------------------------


  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
      :organization_id,
      :title,
      :description,
      :justification,
      :amount,
      :funding_template_id,
      :federal_pcnt,
      :state_pcnt,
      :rejection,
      :act_num,
      :fy_year,
      :pt_num
  ]

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  def self.allowable_params
    FORM_PARAMS
  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  def to_s
    title
  end

  def local_pcnt
    funding_template ? 100 - federal_pcnt - state_pcnt : 0
  end

  def federal_amount
    federal_pcnt * amount / 100.0
  end

  def state_amount
    state_pcnt * amount / 100.0
  end

  def local_amount
    local_pcnt * amount / 100.0
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  def set_defaults
    self.amount ||= 0
    self.federal_pcnt ||= 0
    self.state_pcnt ||= 0
  end
end

#------------------------------------------------------------------------------
#
# FundingRequest
#
# Represents the amount of a fund has been requested by a transit agency to fund
# a capital project wholly or in part
#
#------------------------------------------------------------------------------
class FundingRequest < ActiveRecord::Base

  # Include the object key mixin
  include TransamObjectKey

  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize                  :set_defaults
  before_save                       :update_old_buckets
  after_save                        :update_new_buckets

  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------

  # Has 0 or 1 federal funding line item which it draws on
  belongs_to  :federal_funding_line_item, :class_name => "FundingBucket", :foreign_key => :federal_funding_line_item_id

  # Has 0 or 1 state funding line item which it draws on
  belongs_to  :state_funding_line_item,   :class_name => "FundingBucket", :foreign_key => :state_funding_line_item_id

  # Has 0 or 1 local funding line item which it draws on
  belongs_to  :local_funding_line_item,   :class_name => "FundingBucket", :foreign_key => :local_funding_line_item_id

  # Has a single activity line item that it applies to
  belongs_to  :activity_line_item

  # Each funding request was created and updated by a user
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by_id"
  belongs_to :updator, :class_name => "User", :foreign_key => "updated_by_id"

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------
  #validates :federal_funding_line_item_id,      :presence => :true
  #validates :state_funding_line_item_id,        :presence => :true
  validates :activity_line_item,                :presence => :true
  validates :federal_amount,                    :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}, :allow_nil => true
  validates :state_amount,                      :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}, :allow_nil => true
  validates :local_amount,                      :numericality => {:only_integer => :true, :greater_than_or_equal_to => 0}, :allow_nil => true
  validates :created_by_id,                     :presence => :true
  validates :updated_by_id,                     :presence => :true

  #-----------------------------------------------------------------------------
  # Attributes
  #-----------------------------------------------------------------------------

  attr_accessor   :federal_percent
  attr_accessor   :state_percent
  attr_accessor   :local_percent
  attr_accessor   :total_percent
  attr_accessor   :total_amount

  #------------------------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------------------------

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
    :object_key,
    :federal_funding_line_item_id,
    :state_funding_line_item_id,
    :activity_line_item_id,
    :federal_amount,
    :state_amount,
    :local_amount,
    :funding_request_amount,
    :federal_percent,
    :state_percent,
    :local_percent,
    :total_percent,
    :total_amount
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

  def total_amount
    federal_amount + state_amount + local_amount
  end

  def federal_percentage
    if funding_request_amount > 0
      pcnt = federal_amount / funding_request_amount.to_f * 100.0
    else
      pcnt = 0.0
    end
  end
  def state_percentage
    if funding_request_amount > 0
      pcnt = state_amount / funding_request_amount.to_f * 100.0
    else
      pcnt = 0.0
    end
  end
  def local_percentage
    if funding_request_amount > 0
      pcnt = local_amount / funding_request_amount.to_f * 100.0
    else
      pcnt = 0.0
    end
  end

  def name
    "#{federal_funding_line_item.funding_source.name}" unless federal_funding_line_item.nil?
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  # Set resonable defaults for a new capital project
  def set_defaults
    self.funding_request_amount ||= 0
    self.federal_amount         ||= 0
    self.state_amount           ||= 0
    self.local_amount           ||= 0
    self.federal_percent        = federal_percentage
    self.state_percent          = state_percentage
    self.local_percent          = local_percentage
  end

  def update_old_buckets
    if self.changes.include?('federal_funding_line_item_id') && !self.federal_amount_was.nil?
      f = FundingBucket.find_by(id: self.federal_funding_line_item_id_was)
      f.budget_committed -= self.federal_amount_was
      f.save!
    end
    if self.changes.include?('state_funding_line_item_id') && !self.state_funding_line_item_id_was.nil?
      f = FundingBucket.find_by(id: self.state_funding_line_item_id_was)
      f.budget_committed -= self.state_amount_was
      f.save!
    end
    if self.changes.include?('local_funding_line_item_id') && !self.local_funding_line_item_id_was.nil?
      f = FundingBucket.find_by(id: self.local_funding_line_item_id_was)
      f.budget_committed -= self.local_amount_was
      f.save!
    end
  end

  def update_new_buckets
    if self.federal_funding_line_item_id
      FundingBucket.find_by(id: self.federal_funding_line_item_id).update!(budget_committed: FundingRequest.where(federal_funding_line_item_id: self.federal_funding_line_item_id).sum(:federal_amount))
    end
    if self.state_funding_line_item_id
      FundingBucket.find_by(id: self.state_funding_line_item_id).update!(budget_committed: FundingRequest.where(state_funding_line_item_id: self.state_funding_line_item_id).sum(:state_amount))
    end
    if self.local_funding_line_item_id
      FundingBucket.find_by(id: self.local_funding_line_item_id).update!(budget_committed: FundingRequest.where(local_funding_line_item_id: self.local_funding_line_item_id).sum(:local_amount))
    end
  end

end

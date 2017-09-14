class FundingBucket< ActiveRecord::Base

  # Include the object key mixin
  include TransamObjectKey
  #Include the Funding source mixin
  require 'funding_source'

  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize  :set_defaults
  # before_save        :check_orgs_list


  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------

  # Each funding source was created and updated by a user
  belongs_to :creator, :class_name => "User", :foreign_key => :created_by_id
  belongs_to :updator, :class_name => "User", :foreign_key => :updated_by_id

  belongs_to :funding_template
  has_one    :funding_source, :through => :funding_template
  belongs_to :owner, :class_name => "Organization"

  has_many :grant_purchases, :as => :sourceable, :dependent => :destroy

  belongs_to :bond_request

  belongs_to :target_organization, :class_name => "Organization", :foreign_key => :target_organization_id
  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------

  validates :funding_template_id,       :presence => true
  validates :fy_year,               :presence => true
  validates :budget_amount,             :presence => true, :numericality => {:greater_than_or_equal_to => 0}
  validates :owner_id,                  :presence => true


  #------------------------------------------------------------------------------
  #
  # Scopes
  #
  #------------------------------------------------------------------------------

  # Allow selection of active instances
  scope :active, -> { where(:active => true) }

  scope :federal, -> { joins(funding_template: :funding_source).where('funding_sources.funding_source_type_id = ?', FundingSourceType.find_by(name: 'Federal')) }
  scope :state, -> { joins(funding_template: :funding_source).where('funding_sources.funding_source_type_id = ?', FundingSourceType.find_by(name: 'State')) }
  scope :local, -> { joins(funding_template: :funding_source).where('funding_sources.funding_source_type_id = ?', FundingSourceType.find_by(name: 'Local')) }

  #scope :state_owned -- class method
  scope :agency_owned, -> (org_ids) { org_ids.present? ? joins(:funding_template).where('funding_templates.owner_id = ? AND funding_buckets.owner_id IN (?)', FundingSourceType.find_by(name: 'Agency'), org_ids) : joins(:funding_template).where('funding_templates.owner_id = ?', FundingSourceType.find_by(name: 'Agency')) }

  scope :current, -> (year) { joins(funding_template: :funding_source).where('funding_buckets.fy_year <= ? AND (((funding_buckets.fy_year + funding_sources.life_in_years - 1) >= ?) OR (funding_sources.life_in_years IS NULL))', year, year) }

  # List of hash parameters allowed by the controller
  FORM_PARAMS = [
      :object_key,
      :funding_template_id,
      :owner_id,
      :fy_year,
      :budget_amount,
      :description,
      :line_num,
      :act_num,
      :pt_num,
      :grantee_code,
      :page_num,
      :item_num,
      :bond_request_id,
      :target_organization_id
  ]

  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  def self.allowable_params
    FORM_PARAMS
  end

  def self.state_owned(org_ids)
    buckets = FundingBucket.joins(:funding_template).where(funding_templates: {restricted: false}).where('funding_templates.owner_id = ?', FundingSourceType.find_by(name: 'State'))

    restricted_buckets = FundingBucket.where(funding_templates: {restricted: true}, funding_buckets: {target_organization_id: org_ids})

    if org_ids.present?
      orgs = Organization.where(id: org_ids)
      buckets = buckets.select{|b| (b.funding_template.get_organizations & orgs).any?}
    end

    buckets + restricted_buckets

  end

  def self.find_existing_buckets_from_proxy funding_template_id, start_fiscal_year, end_fiscal_year, owner_id, organizations_with_budgets, name
    # Start to set up the query
    conditions  = []
    values      = []
    existing_buckets = []

    conditions << 'funding_template_id = ?'
    values << funding_template_id

    conditions << 'fy_year >= ?'
    values << start_fiscal_year

    conditions << 'fy_year <= ?'
    values << end_fiscal_year

    unless name.blank?
      conditions << 'name = ?'
      values << name
    end

    if owner_id.to_i < 0
      funding_template = FundingTemplate.find_by(id: funding_template_id)

      conditions << 'owner_id IN (?)'
      orgs = []
      org_ids = []
      if funding_template.owner == FundingSourceType.find_by(name: 'State')
        orgs =  Grantor.active
      else

        organizations = funding_template.get_organizations
        if !organizations_with_budgets.nil? && organizations_with_budgets.length > 0
          organizations.each { |o|
            if organizations_with_budgets.include?(o.id.to_s)
              orgs << o
            end
          }
        else
          orgs = funding_template.get_organizations
        end

      end
      orgs.each { |o| org_ids << o.id }
      values << org_ids
    else
      conditions << 'owner_id = ?'
      values << owner_id
    end


    conditions << 'active = true'
    existing_buckets = FundingBucket.where(conditions.join(' AND '), *values)

    return existing_buckets
  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  def to_s
    name
  end

  def funding_requests
    FundingRequest.where('federal_funding_line_item_id = ? OR state_funding_line_item_id = ? OR local_funding_line_item_id = ?', self.id, self.id, self.id)
  end

  def deleteable?
    funding_requests.count == 0
  end

  def budget_remaining
    self.budget_amount - self.budget_committed if self.budget_amount.present? && self.budget_committed.present?
  end

  def is_bucket_app?
    self.funding_template.contributor == FundingSourceType.find_by(name: 'Agency')
  end

  def set_values_from_proxy bucket_proxy, agency_id=nil
    self.funding_template_id = bucket_proxy.template_id
    self.fy_year = bucket_proxy.fiscal_year_range_start
    self.budget_amount = bucket_proxy.total_amount
    self.budget_committed = 0
    self.owner_id = agency_id.nil? ? bucket_proxy.owner_id : agency_id
    self.active=true

    self.funding_template = FundingTemplate.find_by(id: self.funding_template_id)
    self.owner = Organization.find_by(id: self.owner_id)

    if bucket_proxy.name.blank?
      generate_unique_name
    else
      self.name = bucket_proxy.name
    end
  end

  def fiscal_year_for_name(year)

    # Do some basic work to make sure the year is in an acceptable range
    # Check if the year is in a 2 or 4 digit format. If it is in 2 digits
    # we are all set. if it is in 4 then ignore the first two digits.
    if year < 100 && year > 0
      yr = year
    elsif year > 999 && year < 10000
      yr = year.to_s[2..4].to_i
    end

    first = "%.2d" % yr
    if yr == 99 # when yr == 99, yr + 1 would be 100, which causes: "FY 99-100"
      next_yr = 00
    else
      next_yr = (yr + 1)
    end
    last = "%.2d" % next_yr

    "FY#{first}/#{last}"
  end

  def generate_unique_name
    self.name = "#{self.funding_template.name}-#{self.owner.short_name}-#{fiscal_year_for_name(self.fy_year)}"
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  def set_defaults
    self.budget_committed ||= 0
    self.active = self.active.nil? ? true : self.active
  end

end
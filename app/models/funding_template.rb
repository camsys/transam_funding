class FundingTemplate < ActiveRecord::Base

  # Include the object key mixin
  include TransamObjectKey

  #Include the Funding source mixin
  require 'funding_source'

  #------------------------------------------------------------------------------
  # Callbacks
  #------------------------------------------------------------------------------
  after_initialize  :set_defaults


  #------------------------------------------------------------------------------
  # Associations
  #------------------------------------------------------------------------------

  belongs_to :funding_source
  belongs_to :contributor, :class_name => "FundingOrganizationType"
  belongs_to :owner, :class_name => "FundingOrganizationType"
  belongs_to :creator, class_name: "User", foreign_key: :created_by_user_id

  has_and_belongs_to_many :funding_template_types,  :join_table => :funding_templates_funding_template_types

  # owner organizations
  has_and_belongs_to_many :organizations

  # contributor organizations
  has_and_belongs_to_many    :contributor_organizations, :join_table => :funding_templates_contributor_organizations, :class_name => 'Organization'

  has_many :funding_buckets, :dependent => :destroy
  has_many :draft_budgets, :dependent => :destroy

  has_many :grant_purchases, :as => :sourceable, :dependent => :destroy

  #------------------------------------------------------------------------------
  # Validations
  #------------------------------------------------------------------------------

  validates :funding_source_id,         :presence => true
  validates :name,                      :presence => true, :uniqueness => {scope: :funding_source, message: "must be unique within a funding program"}
  validates :contributor_id,            :presence => true
  validates :owner_id,                  :presence => true
  validates :match_required,            :allow_nil => true, :numericality => {:greater_than => 0.0, :less_than_or_equal_to => 100.0}

  FORM_PARAMS = [
      :funding_source_id,
      :name,
      :external_id,
      :description,
      :contributor_id,
      :owner_id,
      :transfer_only,
      :recurring,
      :match_required,
      :active,
      :restricted,
      {:organization_ids => []},
      {:contributor_organization_ids => []},
      {:funding_template_type_ids=>[]}
  ]

  #------------------------------------------------------------------------------
  #
  # Scopes
  #
  #------------------------------------------------------------------------------

  # Allow selection of active instances
  scope :active, -> { where(funding_source_id: FundingSource.active.ids) }
  scope :federal, -> { joins(:funding_source).where('funding_sources.funding_source_type_id = ?', FundingSourceType.find_by(name: 'Federal')) }
  scope :state, -> { joins(:funding_source).where('funding_sources.funding_source_type_id = ?', FundingSourceType.find_by(name: 'State')) }
  scope :local, -> { joins(:funding_source).where('funding_sources.funding_source_type_id = ?', FundingSourceType.find_by(name: 'Local')) }


  #------------------------------------------------------------------------------
  #
  # Class Methods
  #
  #------------------------------------------------------------------------------

  def self.allowable_params
    FORM_PARAMS
  end

  def self.get_templates_for_agencies org_ids
    templates = []

    self.active.where(contributor: FundingOrganizationType.find_by(code: 'agency')).each do |t|
      templates << t if (t.get_organizations.map{|x| x.id} & org_ids).count > 0 # add template to list if one of orgs is in eligibility
    end

    templates
  end

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  def to_s
    name
  end

  def type_and_name
    "#{funding_source_type.try(:name)}: #{name}"
  end 


  def get_organizations
    self.query_string.present? ? Organization.find_by_sql(self.query_string) : self.organizations
  end

  def funding_template_type_is? funding_template_type_name
    funding_template_types.include?(FundingTemplateType.find_by(name:funding_template_type_name))
  end

  def recurring_string
    recurring ? "Recurring" : "Annual"
  end

  def creator_org
    creator.try(:organization).try(:short_name)
  end

  #Federal/State/Local/Agency
  def funding_source_type
    funding_source.funding_source_type
  end

  #------------------------------------------------------------------------------
  # DotGrants Export
  #------------------------------------------------------------------------------
  def dotgrants_json
    {name: name}
  end

  #------------------------------------------------------------------------------
  #
  # Protected Methods
  #
  #------------------------------------------------------------------------------
  protected

  def set_defaults
    self.active = self.active.nil? ? true : self.active
    self.recurring = self.recurring.nil? ? false : self.recurring
  end
end

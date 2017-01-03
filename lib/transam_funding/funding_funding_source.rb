module FundingFundingSource
  extend ActiveSupport::Concern

  has_many    :funding_templates, :dependent => :destroy
  has_many    :funding_buckets, :through => :funding_templates


  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------

  def deleteable?

    # any bucket/grant must be associated with a template and therefore only need to check template count
    funding_templates.count == 0
  end

end
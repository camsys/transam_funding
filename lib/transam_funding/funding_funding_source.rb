module FundingFundingSource
  extend ActiveSupport::Concern

  included do
    has_many    :funding_templates, :dependent => :destroy
    has_many    :funding_buckets, :through => :funding_templates
  end


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
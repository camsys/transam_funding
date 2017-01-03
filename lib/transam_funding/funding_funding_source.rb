module FundingFundingSource
  extend ActiveSupport::Concern

  has_many    :funding_templates, :dependent => :destroy
  has_many    :funding_buckets, :through => :funding_templates

end
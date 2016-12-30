class FundingBucketType < ActiveRecord::Base

  has_and_belongs_to_many  :funding_buckets

  # Active scope -- always use this scope in forms
  scope :active, -> { where(active: true) }

  def to_s
    name
  end

end
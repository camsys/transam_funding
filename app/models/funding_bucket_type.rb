# --------------------------------
# # NOT USED (I think????) see TTPLAT-1832 or https://wiki.camsys.com/pages/viewpage.action?pageId=51183790
# --------------------------------


class FundingBucketType < ActiveRecord::Base

  has_and_belongs_to_many  :funding_buckets

  # Active scope -- always use this scope in forms
  scope :active, -> { where(active: true) }

  def to_s
    name
  end

end
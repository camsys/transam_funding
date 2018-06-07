class RenameBucketToFundingBucket < ActiveRecord::Migration[4.2]
  def change
    rename_table :buckets, :funding_buckets

  end
end

class RenameBucketTypeToFundingBucketType < ActiveRecord::Migration[4.2]
  def change
    rename_table :bucket_types, :funding_bucket_types
  end
end

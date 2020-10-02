class AddExternalIdToFundingBuckets < ActiveRecord::Migration[5.2]
  def change
    add_column :funding_buckets, :external_id, :string 
  end
end

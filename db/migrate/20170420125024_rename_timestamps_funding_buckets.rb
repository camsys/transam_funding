class RenameTimestampsFundingBuckets < ActiveRecord::Migration
  def change

    # accidentally didnt use t.timestamps

    rename_column :funding_buckets, :created_on, :created_at
    rename_column :funding_buckets, :updated_on, :updated_at
  end
end

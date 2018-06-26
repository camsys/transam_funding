
class DropBucketTypeColumn< ActiveRecord::Migration[4.2]
  def change
    remove_column :funding_buckets, :bucket_type_id
  end
end

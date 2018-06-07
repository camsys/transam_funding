class ChangeUserActivityLineItemFiltersFunding < ActiveRecord::Migration[4.2]
  def change
    rename_column :user_activity_line_item_filters, :funding_bucket_id, :funding_buckets
    change_column :user_activity_line_item_filters, :funding_buckets, :string

    add_column :user_activity_line_item_filters, :funding_bucket_query_string, :string
  end
end

class AddFieldsToUserActivityLineItemFilters < ActiveRecord::Migration[4.2]
  def change
    add_column :user_activity_line_item_filters, :funding_bucket_id, :integer
    add_column :user_activity_line_item_filters, :not_fully_funded, :boolean
  end
end

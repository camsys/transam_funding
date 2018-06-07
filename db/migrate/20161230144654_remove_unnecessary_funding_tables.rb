class RemoveUnnecessaryFundingTables < ActiveRecord::Migration[4.2]
  def change
    if ActiveRecord::Base.connection.table_exists? :funding_plans
      drop_table :funding_plans
    end

    if ActiveRecord::Base.connection.table_exists? :budget_amounts
      drop_table :budget_amounts
    end

    if ActiveRecord::Base.connection.table_exists? :funding_requests
      add_column :funding_requests, :local_funding_line_item_id, :integer
    end

  end
end

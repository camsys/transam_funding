class AddCreatedByToFundingTemplate < ActiveRecord::Migration[5.2]
  def change
    add_column :funding_templates, :created_by_user_id, :bigint
     add_foreign_key :funding_templates, :users, column: :created_by_user_id, primary_key: :id
  end
end

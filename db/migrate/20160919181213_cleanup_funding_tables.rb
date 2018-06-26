class CleanupFundingTables < ActiveRecord::Migration[4.2]
  def change
    rename_column :funding_templates, :contributer_id, :contributor_id
    add_column :funding_templates, :all_organizations, :boolean
    add_column :funding_templates, :external_id, :string, :limit => 32
  end
end

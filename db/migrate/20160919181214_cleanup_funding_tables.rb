class CleanupFundingTables < ActiveRecord::Migration[4.2]
  def change
    unless column_exists? :funding_templates, :contributor_id
      rename_column :funding_templates, :contributer_id, :contributor_id
    end
    unless column_exists? :funding_templates, :all_organizations
      add_column :funding_templates, :all_organizations, :boolean
    end
    unless column_exists? :funding_templates, :external_id
      add_column :funding_templates, :external_id, :string, :limit => 32
    end
  end
end

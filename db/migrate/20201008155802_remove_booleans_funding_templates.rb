class RemoveBooleansFundingTemplates < ActiveRecord::Migration[5.2]
  def change
    #remove_column :funding_templates, :query_string
    remove_column :funding_templates, :create_multiple_agencies
    remove_column :funding_templates, :create_multiple_buckets_for_agency_year
  end
end

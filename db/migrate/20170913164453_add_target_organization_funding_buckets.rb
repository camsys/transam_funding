class AddTargetOrganizationFundingBuckets < ActiveRecord::Migration[4.2]
  def change
    add_column :funding_buckets, :target_organization_id, :integer
    add_column :funding_templates, :restricted, :boolean, after: :create_multiple_buckets_for_agency_year
  end
end

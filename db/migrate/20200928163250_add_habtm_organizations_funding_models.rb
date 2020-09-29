class AddHabtmOrganizationsFundingModels < ActiveRecord::Migration[5.2]
  def change
    create_table :funding_sources_organizations, :id => false do |t|
      t.references :funding_source,       index: true
      t.references :organization,           index: true
    end

    create_table :funding_templates_contributor_organizations, :id => false do |t|
      t.references :funding_template, index: {name: 'template_contributor_template_idx'}
      t.references :organization, index: {name: 'template_contributor_organization_idx'}
    end

    add_reference :funding_buckets, :contributor, index: true
  end
end

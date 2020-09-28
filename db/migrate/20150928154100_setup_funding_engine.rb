class SetupFundingEngine < ActiveRecord::Migration[5.2]

  # this migration though created in 2020 is to setup the db for clients/apps without the funding engine
  # older work didnt use migrations properly so we need this cleanup
  def change
    # this is an informal way to check if already have funding engine
    unless ActiveRecord::Base.connection.table_exists? :funding_requests

      execute "delete from schema_migrations where version = '20160915130127';"
      execute "delete from schema_migrations where version = '20160919181213';"

      if ActiveRecord::Base.connection.table_exists? :funding_templates
        drop_table :funding_templates
      end
      if ActiveRecord::Base.connection.table_exists? :funding_template_types
        drop_table :funding_template_types
      end
      if ActiveRecord::Base.connection.table_exists? :funding_templates_organizations
        drop_table :funding_templates_organizations
      end
      if ActiveRecord::Base.connection.table_exists? :funding_templates_funding_template_types
        drop_table :funding_templates_funding_template_types
      end

      create_table :funding_requests do |t|
        t.string :object_key, index: true, limit: 12, null: false
        t.references :activity_line_item, index: true
        t.references :federal_funding_line_item
        t.references :state_funding_line_item
        t.integer :federal_amount
        t.integer :state_amount
        t.integer :local_amount
        t.references :created_by
        t.references :updated_by

        t.timestamps
      end
    end
  end
end

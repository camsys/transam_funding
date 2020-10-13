class RemoveBooleansFundingTemplates < ActiveRecord::Migration[5.2]
  def change
    if FundingTemplate.distinct.pluck(:query_string).select{|x| !x.blank? }.empty?
      remove_column :funding_templates, :query_string
    end
    remove_column :funding_templates, :create_multiple_agencies
    remove_column :funding_templates, :create_multiple_buckets_for_agency_year
  end
end

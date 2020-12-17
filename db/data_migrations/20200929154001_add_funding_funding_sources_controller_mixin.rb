class AddFundingFundingSourcesControllerMixin < ActiveRecord::DataMigration
  def up
    SystemConfigExtension.create!({engine_name: 'funding', class_name: 'FundingSourcesController', extension_name: 'FundableFundingSourcesController', active: true})
  end
end
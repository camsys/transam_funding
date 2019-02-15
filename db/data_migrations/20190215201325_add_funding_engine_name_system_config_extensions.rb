class AddFundingEngineNameSystemConfigExtensions < ActiveRecord::DataMigration
  def up
    system_config_extensions = [
        {class_name: 'FundingSource', extension_name: 'FundingFundingSource', active: true},
        {class_name: 'CapitalProject', extension_name: 'TransamFundableCapitalProject', active: true},
        {class_name: 'ActivityLineItem', extension_name: 'TransamFundable', active: true}
    ]

    system_config_extensions.each do |config|
      SystemConfigExtension.find_by(config).update!(engine_name: 'funding')
    end
  end
end
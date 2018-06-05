class AddFundingSystemConfigExtensions < ActiveRecord::DataMigration
  def up
    system_config_extensions = [
        {class_name: 'FundingSource', extension_name: 'FundingFundingSource', active: true}

    ]

    system_config_extensions.each do |extension|
      SystemConfigExetnsion.create!(extension)
    end
  end
end
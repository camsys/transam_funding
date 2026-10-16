Rails.configuration.to_prepare do

  AssetsController.class_eval do
    include TransamAccountingAssetsController
  end

  Organization.class_eval do
    include TransamAccountable
  end

  Policy.class_eval do
    include TransamAccountingPolicy
  end

  Vendor.class_eval do
    include TransamAccountingVendor
  end
end

task create_bucket_types: :environment do
  formula_bucket_type = FundingBucketType.new(:active => 1, :name => 'Formula', :description => 'Formula Bucket')
  existing_bucket_type = FundingBucketType.new(:active => 1, :name => 'Existing Grant', :description => 'Existing Grant')
  grant_application_bucket_type = FundingBucketType.new(:active => 1, :name => 'Grant Application', :description => 'Grant Application Bucket')

  formula_bucket_type.save
  existing_bucket_type.save
  grant_application_bucket_type.save
end
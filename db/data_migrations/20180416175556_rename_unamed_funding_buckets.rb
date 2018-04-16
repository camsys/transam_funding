class RenameUnamedFundingBuckets < ActiveRecord::DataMigration
  def up
    nameless_buckets = FundingBucket.where(name: '')

    nameless_buckets.each {|bucket|
      bucket.generate_unique_name
      bucket.save
    }
  end
end
class RenameFundingBucketFiscalYearColumnToFyYear < ActiveRecord::Migration
  def change
    unless column_exists? :funding_buckets, :fy_year
      rename_column :funding_buckets, :fiscal_year, :fy_year
    end
  end
end

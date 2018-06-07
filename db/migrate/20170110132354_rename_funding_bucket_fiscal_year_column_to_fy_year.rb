class RenameFundingBucketFiscalYearColumnToFyYear < ActiveRecord::Migration[4.2]
  def change
    unless column_exists? :funding_buckets, :fy_year
      rename_column :funding_buckets, :fiscal_year, :fy_year
    end
  end
end

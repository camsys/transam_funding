class AddBondFieldsFundingBuckets < ActiveRecord::Migration[4.2]
  def change
    add_column :funding_buckets, :line_num, :string
    add_column :funding_buckets, :act_num, :string
    add_column :funding_buckets, :pt_num, :string
    add_column :funding_buckets, :grantee_code, :string
    add_column :funding_buckets, :page_num, :string
    add_column :funding_buckets, :item_num, :string
  end
end

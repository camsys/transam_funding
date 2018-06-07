class AddBondRequestFundingBuckets < ActiveRecord::Migration[4.2]
  def change
    add_reference :funding_buckets, :bond_request

    add_column :bond_requests, :line_num, :string, after: :pt_num
    add_column :bond_requests, :page_num, :string, after: :line_num
    add_column :bond_requests, :item_num, :string, after: :page_num
  end
end

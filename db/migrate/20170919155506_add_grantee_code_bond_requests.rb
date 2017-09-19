class AddGranteeCodeBondRequests < ActiveRecord::Migration
  def change
    add_column :bond_requests, :grantee_code, :string, after: :page_num
  end
end

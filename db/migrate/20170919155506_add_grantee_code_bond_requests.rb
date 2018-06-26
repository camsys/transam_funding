class AddGranteeCodeBondRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :bond_requests, :grantee_code, :string, after: :page_num
  end
end

class ChangePcntsBondRequests < ActiveRecord::Migration[4.2]
  def change
    change_column :bond_requests, :federal_pcnt, :float
    change_column :bond_requests, :state_pcnt, :float
  end
end

class ChangePcntsBondRequests < ActiveRecord::Migration
  def change
    change_column :bond_requests, :federal_pcnt, :float
    change_column :bond_requests, :state_pcnt, :float
  end
end

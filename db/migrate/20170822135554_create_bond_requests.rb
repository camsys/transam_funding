class CreateBondRequests < ActiveRecord::Migration
  def change
    create_table :bond_requests do |t|
      t.string    :object_key, index: true, limit: 12, null: false
      t.references :organization, index: true
      t.string :title
      t.text :description
      t.text :justification
      t.string :state
      t.integer :amount
      t.references :funding_template
      t.integer :federal_pcnt
      t.integer :state_pcnt
      t.text :rejection
      t.string :act_num
      t.integer :fy_year
      t.string :pt_num
      t.integer :created_by_user_id
      t.integer :updated_by_user_id
      t.integer :submitted_by_user_id

      t.timestamps
      t.datetime :submitted_at
    end
  end
end

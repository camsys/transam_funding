class UpdateFundingRequestPrecision < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      change_table :funding_requests do |t|
        dir.up   { t.change :federal_amount, :int8, :limit => 8  }
        dir.down { t.change :federal_amount, :integer }
        dir.up   { t.change :state_amount, :int8, :limit => 8  }
        dir.down { t.change :state_amount, :integer }
        dir.up   { t.change :local_amount, :int8, :limit => 8  }
        dir.down { t.change :local_amount, :integer }
        dir.up   { t.change :funding_request_amount, :int8, :limit => 8  }
        dir.down { t.change :funding_request_amount, :integer }
      end
    end
  end
end

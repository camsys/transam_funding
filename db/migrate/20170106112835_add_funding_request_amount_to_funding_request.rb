class AddFundingRequestAmountToFundingRequest < ActiveRecord::Migration
  def change
    unless column_exists? :funding_requests, :funding_request_amount
      add_column :funding_requests, :funding_request_amount, :integer, :null => false
    end
  end
end

require "rails_helper"

# TTPLAT-3091 instance 17: the scheduler's loader and edit_asset_in_modal actions were removed.
# Ask the router directly, not the controller.
RSpec.describe "Removed routes", type: :routing do

  it 'no longer routes GET /scheduler/loader' do
    expect(:get => '/scheduler/loader').not_to be_routable
  end

  it 'no longer routes POST /scheduler/edit_asset_in_modal' do
    expect(:post => '/scheduler/edit_asset_in_modal').not_to be_routable
  end
end

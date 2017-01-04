Rails.application.routes.draw do

  # Budget Forcast
  # resources :budgets,   :only => [:index] do
  #   collection do
  #     post  'set'
  #     post  'alter'
  #   end
  # end

  # Asset replacement/rehabilitation
  resources :scheduler, :only => [:index] do
    collection do
      post  'scheduler_action'
      get   'scheduler_swimlane_action'
      post  'scheduler_ali_action'
      get   'scheduler_ali_action'
      get   'loader'
      post  'edit_asset_in_modal'
      post  'update_cost_modal'
      post  'add_unding_plan_modal'
    end
  end

  resources :capital_projects, :only => [] do
    resources :activity_line_items, :only => [] do
      resources :funding_requests
    end
  end

end

Rails.application.routes.draw do
  resources :funding_buckets do
    collection do
      get 'my_funds'

      get 'find_templates_from_program_id'
      get 'find_organizations_from_template_id'
      get 'find_configuration_options_from_template_id'
      get 'find_existing_buckets_for_create'
      get 'find_number_of_missing_buckets_for_update'
      get 'find_expected_escalation_percent'
      get 'find_template_based_fiscal_year_range'

      get 'new_bucket_app'
      post 'create_bucket_app'
    end
    member do
      get 'edit_bucket_app'
      patch 'update_bucket_app'
      delete 'destroy_bucket_app'
    end
  end


  resources :funding_sources, :path => :funding_programs do
    collection do
      get 'details'
    end
    resources :comments
    resources :documents
  end

  resources :funding_templates do
    collection do
      get 'find_match_required_from_funding_source_id'
    end
  end

  resources :grants do
    member do
      get 'summary_info'
    end
    resources :comments
    resources :documents
  end

  resources :general_ledger_accounts

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

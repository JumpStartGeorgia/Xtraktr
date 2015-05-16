BootstrapStarter::Application.routes.draw do

  devise_for :users, skip: [:sessions, :passwords, :registrations, :confirmations], :path_names => {:sign_in => 'login', :sign_out => 'logout'}, controllers: { omniauth_callbacks: 'omniauth_callbacks' }
	#--------------------------------
	# all resources should be within the scope block below
	#--------------------------------
	scope ":locale", locale: /#{I18n.available_locales.join("|")}/ do

		# devise_for :users, :path_names => {:sign_in => 'login', :sign_out => 'logout'},
		# 									 :controllers => {:omniauth_callbacks => "users/omniauth_callbacks"}


    get 'omniauth/:provider' => 'omniauth#localized', as: :localized_omniauth
    devise_for :users, skip: :omniauth_callbacks, :path_names => {:sign_in => 'login', :sign_out => 'logout'}, controllers: { registrations: 'users/registrations', sessions: 'users/sessions'} 


    match '/admin', :to => 'admin#index', :as => :admin, :via => :get
    match '/admin/download_api_requests', :to => 'admin#download_api_requests', :as => :admin_download_api_requests, :via => :get, :defaults => { :format => 'csv' }
    match '/admin/download_download_requests', :to => 'admin#download_download_requests', :as => :admin_download_download_requests, :via => :get, :defaults => { :format => 'csv' }
    namespace :admin do
      resources :shapesets
      resources :page_contents
      resources :users
      resources :api_versions, :except => [:show] do
        resources :api_methods, :except => [:index]
      end
    end

    resources :datasets do
      resources :questions, :only => [:index, :show, :edit, :update] do
        collection do
          get 'mass_changes'
          post 'mass_changes'
          post 'load_mass_changes_questions'
          post 'load_mass_changes_answers'
        end
      end
      member do
        get 'explore'
        get 'warnings'
        get 'exclude_questions'
        post 'exclude_questions'
        get 'exclude_answers'
        post 'exclude_answers'
        get 'can_exclude_answers'
        post 'can_exclude_answers'
        get 'mappable'
        get 'mappable_form'
        post 'mappable_form'
        get 'mappable_form_edit'
        post 'mappable_form_edit'
        delete 'remove_mapping'
        post 'question_answers', :defaults => { :format => 'json' }
        post 'add_highlight'
        post 'remove_highlight'
        get 'highlights'
        post 'highlights'
        post 'home_page_highlight'
      end
    end

    resources :time_series do
      resources :time_series_questions, :only => [:index, :show, :new, :create, :edit, :update], :path => 'questions', :as => 'questions'
      member do
        get 'explore'
        get 'automatically_assign_questions'
        post 'add_highlight'
        post 'remove_highlight'
        get 'highlights'
        post 'highlights'
        post 'home_page_highlight'
      end
    end

    # api
    match '/api', to: 'api#index', as: :api, via: :get
    namespace :api do
      match '/v1', to: 'v1#index', as: :v1, via: :get
      match '/v1/documentation(/:method)', to: 'v1#documentation', as: :v1_documentation, via: :get
      match '/v1/dataset_catalog', to: 'v1#dataset_catalog', as: :v1_dataset_catalog, via: :get, :defaults => { :format => 'json' }
      match '/v1/dataset', to: 'v1#dataset', as: :v1_dataset, via: :get, :defaults => { :format => 'json' }
      match '/v1/dataset_codebook', to: 'v1#dataset_codebook', as: :v1_dataset_codebook, via: :get, :defaults => { :format => 'json' }
      match '/v1/dataset_analysis', to: 'v1#dataset_analysis', as: :v1_dataset_analysis, via: :get, :defaults => { :format => 'json' }
      match '/v1/time_series_catalog', to: 'v1#time_series_catalog', as: :v1_time_series_catalog, via: :get, :defaults => { :format => 'json' }
      match '/v1/time_series', to: 'v1#time_series', as: :v1_time_series, via: :get, :defaults => { :format => 'json' }
      match '/v1/time_series_codebook', to: 'v1#time_series_codebook', as: :v1_time_series_codebook, via: :get, :defaults => { :format => 'json' }
      match '/v1/time_series_analysis', to: 'v1#time_series_analysis', as: :v1_time_series_analysis, via: :get, :defaults => { :format => 'json' }
    end    

    # embed pages
    match '/embed', to: 'embed#index', as: :embed, via: :get
    namespace :embed do
      match '/v1/:id', to: 'v1#index', as: :v1, via: :get
    end    

    # root pages
    match '/contact', :to => 'root#contact', :as => :contact, :via => [:get, :post]
    match '/download/:id', :to => 'root#download', :as => :download, :via => :get
    match '/download_request', :to => 'root#download_request', :as => :download_request, :via => :get
    match '/instructions', :to => 'root#instructions', :as => :instructions, :via => :get
    match '/notes', :to => 'root#notes', :as => :notes, :via => :get
		match '/explore_data', :to => 'root#explore_data', :as => :explore_data, :via => :get
		match '/explore_data/:id', :to => 'root#explore_data_dashboard', :as => :explore_data_dashboard, :via => :get
    match '/explore_data/:id/explore', :to => 'root#explore_data_show', :as => :explore_data_show, :via => :get
    match '/explore_time_series', :to => 'root#explore_time_series', :as => :explore_time, :via => :get
    match '/explore_time_series/:id', :to => 'root#explore_time_series_dashboard', :as => :explore_time_series_dashboard, :via => :get
    match '/explore_time_series/:id/explore', :to => 'root#explore_time_series_show', :as => :explore_time_series_show, :via => :get
    match '/private_share/:id', :to => 'root#private_share', :as => :private_share, :via => :get

    match '/settings', :to => 'settings#index', :as => :settings, :via => [:get, :put]
    match '/settings/get_api_token', :to => 'settings#get_api_token', :as => :settings_get_api_token, :via => :post
    match '/settings/delete_api_token/:id', :to => 'settings#delete_api_token', :as => :settings_delete_api_token, :via => :delete

		root :to => 'root#index'
	  match "*path", :to => redirect("/#{I18n.default_locale}") # handles /en/fake/path/whatever
	end

	match '', :to => redirect("/#{I18n.default_locale}") # handles /
	match '*path', :to => redirect("/#{I18n.default_locale}/%{path}") # handles /not-a-locale/anything

end

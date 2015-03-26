BootstrapStarter::Application.routes.draw do

	#--------------------------------
	# all resources should be within the scope block below
	#--------------------------------
	scope ":locale", locale: /#{I18n.available_locales.join("|")}/ do

		match '/admin', :to => 'admin#index', :as => :admin, :via => :get
		devise_for :users, :path_names => {:sign_in => 'login', :sign_out => 'logout'},
											 :controllers => {:omniauth_callbacks => "omniauth_callbacks"}

    namespace :admin do
      resources :shapesets
      resources :pages
      resources :users
    end

    resources :datasets do
      resources :questions, :only => [:index, :show, :edit, :update] do
        collection do
          get 'mass_changes'
          post 'mass_changes'
        end
      end
      member do
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
      end
    end

    resources :time_series do
      resources :time_series_questions, :only => [:index, :show, :new, :create, :edit, :update], :path => 'questions', :as => 'questions'
      member do
        get 'automatically_assign_questions'
      end
    end

    # root pages
		match '/explore_data', :to => 'root#explore_data', :as => :explore_data, :via => :get
		match '/explore_data/:id', :to => 'root#explore_data_show', :as => :explore_data_show, :via => :get
    match '/explore_time_series', :to => 'root#explore_time_series', :as => :explore_time_series, :via => :get
    match '/explore_time_series/:id', :to => 'root#explore_time_series_show', :as => :explore_time_series_show, :via => :get
    match '/private_share/:id', :to => 'root#private_share', :as => :private_share, :via => :get

		root :to => 'root#index'
	  match "*path", :to => redirect("/#{I18n.default_locale}") # handles /en/fake/path/whatever
	end

	match '', :to => redirect("/#{I18n.default_locale}") # handles /
	match '*path', :to => redirect("/#{I18n.default_locale}/%{path}") # handles /not-a-locale/anything

end

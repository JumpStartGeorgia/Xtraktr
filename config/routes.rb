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
      member do
        get 'warnings'
        get 'exclude_questions'
        post 'exclude_questions'
      end
    end

    # root pages
		match '/explore_data', :to => 'root#explore_data', :as => :explore_data, :via => :get
		match '/explore_data/:id', :to => 'root#explore_data_show', :as => :explore_data_show, :via => :get
    match '/private_share/:id', :to => 'root#private_share', :as => :private_share, :via => :get

		root :to => 'root#index'
	  match "*path", :to => redirect("/#{I18n.default_locale}") # handles /en/fake/path/whatever
	end

	match '', :to => redirect("/#{I18n.default_locale}") # handles /
	match '*path', :to => redirect("/#{I18n.default_locale}/%{path}") # handles /not-a-locale/anything

end

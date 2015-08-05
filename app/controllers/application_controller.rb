class ApplicationController < ActionController::Base

  layout 'app'
  protect_from_forgery

  PER_PAGE_COUNT = 6

  DEVISE_CONTROLLERS = ['users/sessions', 'users/registrations', 'devise/passwords']

	before_filter :set_locale
	before_filter :is_browser_supported?
	before_filter :preload_global_variables
	before_filter :initialize_gon
	before_filter :store_location
  # before_filter :check_user_status

  layout :layout_by_resource

	unless Rails.application.config.consider_all_requests_local
		rescue_from Exception,
		            :with => :render_error
		rescue_from ActiveRecord::RecordNotFound,
		            :with => :render_not_found
		rescue_from ActionController::RoutingError,
		            :with => :render_not_found
		rescue_from ActionController::UnknownController,
		            :with => :render_not_found
		rescue_from ActionController::UnknownAction,
		            :with => :render_not_found
    rescue_from Mongoid::Errors::DocumentNotFound,
                :with => :render_not_found

	end

	Browser = Struct.new(:browser, :version)
	SUPPORTED_BROWSERS = [
		Browser.new("Chrome", "15.0"),
		Browser.new("Safari", "4.0.2"),
		Browser.new("Firefox", "10.0.2"),
		Browser.new("Internet Explorer", "9.0"),
		Browser.new("Opera", "11.0")
	]

	def is_browser_supported?
		@user_agent = UserAgent.parse(request.user_agent)
logger.debug "////////////////////////// BROWSER = #{@user_agent}"
#		if SUPPORTED_BROWSERS.any? { |browser| @user_agent < browser }
#			# browser not supported
#logger.debug "////////////////////////// BROWSER NOT SUPPORTED"
#			render "layouts/unsupported_browser", :layout => false
#		end
	end


	def set_locale
    if params[:locale] and I18n.available_locales.include?(params[:locale].to_sym)
      I18n.locale = params[:locale]
    else
      I18n.locale = I18n.default_locale
    end
	end

  def default_url_options(options={})
    { :locale => I18n.locale }
  end

	def preload_global_variables
    # flag to indicate if the app is currently running in unicef or xtraktr mode
    @is_xtraktr = false

    # locale key name to get text specific to xtraktr or other
    @app_key_name = @is_xtraktr ? 'xtraktr' : 'unicef'

    # indicate that whether login should allow local and omniauth or just locale
	  @enable_omniauth = @is_xtraktr

    # get the id for addthis sharing
    @addthis_id =  @is_xtraktr ? (Rails.env.production? ? ENV['XTRAKTR_ADDTHIS_PROFILE_ID'] : ENV['XTRAKTR_ADDTHIS_PROFILE_ID_DEV'])
                            : (Rails.env.production? ? ENV['UNICEF_ADDTHIS_PROFILE_ID']  : ENV['UNICEF_ADDTHIS_PROFILE_ID_DEV'])


    # indicate which role has access to edit datasets/time series
    @data_editor_role = @is_xtraktr ? User::ROLES[:user] : User::ROLES[:data_editor]
    @site_admin_role = @is_xtraktr ? User::ROLES[:admin] : User::ROLES[:site_admin]

    # for loading extra css/js files
    @css = []
    @js = []

    # get the api key for the app user
    api_key = User.find_by(email: 'application@mail.com').api_keys.first
    @app_api_key = api_key.key if api_key.present?

    # show h1 title by default
    @show_title = true

    # get public question count
    @public_question_count = Stats.public_question_count

    @xtraktr_url = "http://xtraktr.jumpstart.ge"
  end

	def initialize_gon
		gon.set = true
		gon.highlight_first_form_field = false
    gon.app_api_key = @app_api_key

	  gon.datatable_i18n_url = "/datatable_#{I18n.locale}.txt"

    gon.visual_types = Highlight::VISUAL_TYPES

    gon.get_highlight_desc_link = highlights_get_description_path
	end

  # in order for the downloads to work properly, the user must have entered all required fields (name, age, etc)
  # - this requirement did not exist when the site was created so some users may not have all fields entered
  # - if this is the case, send them to the settings page
  # def check_user_status
  #   if !@is_xtraktr && user_signed_in? && current_user.terms == false && request.path != settings_path
  #     redirect_to settings_path, alert: I18n.t('app.msgs.missing_user_info')
  #   end
  # end

  def layout_by_resource
    if !DEVISE_CONTROLLERS.index(params[:controller]).nil? && request.xhr?
      nil
    else
      "application"
    end
  end

	def after_sign_in_path_for(resource)
		session[:previous_urls].last || request.env['omniauth.origin'] || root_path(:locale => I18n.locale)
	end

  def valid_role?(role)
    redirect_to root_path, :notice => t('app.msgs.not_authorized') if !current_user || !current_user.role?(role)
  end

	# store the current path so after login, can go back
	# only record the path if this is not an ajax call and not a users page (sign in, sign up, etc)
	def store_location
		session[:previous_urls] ||= []

    if session[:download_url].present? && !user_signed_in? && !params[:d].present? && !(params[:controller] == 'users/registrations' && params[:action] == 'create' )
      session[:download_url] = nil
    end

    if params[:action] == 'download_request' && request.xhr? && !user_signed_in? &&
      session[:download_url] = request.fullpath
    end

    if request.fullpath.index("/download/").nil?
  		if session[:previous_urls].first != request.fullpath &&
          params[:format] != 'js' && params[:format] != 'json' && !request.xhr? &&
          request.fullpath.index("/users/").nil? &&
          request.fullpath.index("/embed/").nil?

  	    session[:previous_urls].unshift request.fullpath
      elsif session[:previous_urls].first != request.fullpath &&
         request.xhr? && !request.fullpath.index("/users/").nil?  &&
          !request.fullpath.index("/embed/").nil?&&
         params[:return_url].present?

        session[:previous_urls].unshift params[:return_url]
  		end
    end

		session[:previous_urls].pop if session[:previous_urls].count > 1
    #Rails.logger.debug "****************** prev urls session = #{session[:previous_urls]}"
	end

  # sort a group of objects by sort_order field
  # if object item sort_order is nil, move it to the end of the list of objects
  def sort_objects_with_sort_order(objects)
    sorted = []
    if objects.present?
      sorted =objects.select{|x| x.sort_order.present?}.sort_by{|x| x.sort_order} + objects.select{|x| x.sort_order.nil?}
    end
    return sorted
  end

  def clean_filename(filename)
    filename.strip.latinize.to_ascii.gsub(' ', '_').gsub(/[\\ \/ \: \* \? \" \< \> \| \, \. ]/,'')
  end

  # remove unwanted items from the filtered params
  def clean_filtered_params(params)
    params.except('access_token', 'controller', 'action', 'format', 'locale')
  end

  # add options to show the dataset nav bar
  def add_dataset_nav_options(options={})
    show_title = options[:show_title].nil? ? true : options[:show_title]
    set_url = options[:set_url].nil? ? true : options[:set_url]

    @css.push("datasets.css")
    @dataset_url = dataset_path(@dataset) if set_url
    @is_dataset_admin = true
    gon.is_admin = true

    @show_title = show_title
  end

  # add options to show the time series nav bar
  def add_time_series_nav_options(options={})
    show_title = options[:show_title].nil? ? true : options[:show_title]
    set_url = options[:set_url].nil? ? true : options[:set_url]

    @css.push("time_series.css")
    @time_series_url = time_series_path(@time_series) if set_url
    @is_time_series_admin = true
    gon.is_admin = true

    @show_title = show_title
  end


  # set variables need for the tabbed translation forms
  def set_tabbed_translation_form_settings(tinymce_template='default')
    @languages = Language.sorted
    @css.push('tabbed_translation_form.css', 'select2.css')
    @js.push('tabbed_translation_form.js', 'select2/select2.min.js')
    gon.tinymce_options = Hash[TinyMCE::Rails.configuration[tinymce_template].options.map{|(k,v)| [k.to_s,v.class == Array ? v.join(',') : v]}]

    if tinymce_template != 'default'
      @css.push('shCore.css')
      @js.push('shCore.js', 'shBrushJScript.js')
    end
  end

  # tell active-model-serializers gem to not include root name in json output
  def default_serializer_options
    { root: false }
  end

  #######################
  ## get data for explore view
  #######################
  def explore_data_generator(dataset, show_private_questions=false)
    # if the language parameter exists and it is valid, use it instead of the default current_locale
    if params[:language].present? && dataset.languages.include?(params[:language])
      dataset.current_locale = params[:language]
    end

    # get appropriate questions
    @questions = show_private_questions == true ? dataset.questions.for_analysis_with_exclude_questions : dataset.questions.for_analysis

    # get the appropriate questions/groups in the correct order
    question_type = show_private_questions == true ? 'analysis_with_exclude_questions' : 'analysis'
    @items = dataset.arranged_items(question_type: question_type, include_groups: true, include_subgroups: true, include_questions: true)


    if @questions.present?

      # initialize variables
      # start with a random question
      @question_code = @questions.map{|x| x.code}.sample
      @broken_down_by_code = nil
      @filtered_by_code = nil

      # check for valid question value
      if params[:question_code].present? && @questions.index{|x| x.code == params[:question_code]}.present?
        @question_code = params[:question_code]
      end

      # check for valid broken down by value
      if params[:broken_down_by_code].present? && @questions.index{|x| x.code == params[:broken_down_by_code]}.present?
        @broken_down_by_code = params[:broken_down_by_code]
      end

      # check for valid filter value
      if params[:filtered_by_code].present?  && @questions.index{|x| x.code == params[:filtered_by_code]}.present?
        @filtered_by_code = params[:filtered_by_code]
      end
    end


    respond_to do |format|
      format.html{
        # load the shapes if needed
        if dataset.is_mappable? && dataset.urls.shape_file.present?
          @shapes_url = dataset.urls.shape_file
        end

        # add the required assets
        @css.push('bootstrap-select.min.css', "tabs.css", "explore.css", "datasets.css")
        @js.push('bootstrap-select.min.js', "explore.js", "explore_data.js", 'highcharts.js', 'highcharts-map.js', 'highcharts-exporting.js')

        gon.embed_button_link = embed_v2_url('replace') if dataset.public?

        # record javascript variables
        gon.hover_region = I18n.t('explore_data.hover_region')
        gon.na = I18n.t('explore_data.na')
        gon.percent = I18n.t('explore_data.percent')
        gon.table_questions_header = I18n.t('app.common.questions')

        set_gon_highcharts
        set_gon_datatables

        gon.explore_data = true
        gon.dataset_id = params[:id]
        gon.api_dataset_analysis_path = api_v2_dataset_analysis_path

      }
    end
  end



  #######################
  ## get data for explore view
  #######################
  def explore_time_series_generator(time_series)
    # if the language parameter exists and it is valid, use it instead of the default current_locale
    if params[:language].present? && time_series.languages.include?(params[:language])
      time_series.current_locale = params[:language]
    end

    # the questions for cross tab can only be those that have code answers and are not excluded
    @questions = time_series.questions

    if @questions.present?

      # initialize variables
      # start with a random question
      @question_code = @questions.map{|x| x.code}.sample
      @filter_by_code = nil

      # check for valid question value
      if params[:question_code].present? && @questions.index{|x| x.code == params[:question_code]}.present?
        @question_code = params[:question_code]
      end

      # check for valid filter value
      if params[:filtered_by_code].present?  && @questions.index{|x| x.code == params[:filtered_by_code]}.present?
        @filtered_by_code = params[:filtered_by_code]
      end
    end

    respond_to do |format|
      format.html{
        # add the required assets
        @css.push('bootstrap-select.min.css', "tabs.css", "explore.css", "time_series.css")
        @js.push('bootstrap-select.min.js', "explore.js", "explore_time_series.js", 'highcharts.js', 'highcharts-exporting.js')

        gon.embed_button_link = embed_v2_url('replace') if time_series.public?

        # record javascript variables
        gon.na = I18n.t('explore_time_series.na')
        gon.percent = I18n.t('explore_time_series.percent')
        gon.table_questions_header = I18n.t('app.common.questions')

        set_gon_highcharts
        set_gon_datatables

        gon.explore_time_series = true
        gon.time_series_id = params[:id]
        gon.api_time_series_analysis_path = api_v2_time_series_analysis_path

      }
    end
  end

  # generate the data needed for the embed_id
  # output: {type, title, dashboard_link, explore_link, error, visual_type, js}
  def get_highlight_data(embed_id, highlight_id=nil, use_admin_link=nil)
    highlight_id ||= SecureRandom.urlsafe_base64
    output = {highlight_id:highlight_id, id:nil, type:nil, title:nil, dashboard_link:nil, explore_link:nil, error:false, visual_type:nil, js:{}, has_data:false}
    options = nil

    begin
      options = Rack::Utils.parse_query(Base64.urlsafe_decode64(embed_id))
    rescue
      output[:error] = true
    end

    # options must be present with dataset or time series id and question code; all other options are not required
    if !output[:error] && options.present? && (options['dataset_id'].present? || options['time_series_id'].present?) && options['question_code'].present?
      options = clean_filtered_params(options)

      output[:visual_type] = options['visual_type']

      if options['dataset_id'].present?
        output[:type] = 'dataset'

        data = Api::V2.dataset_analysis(options['dataset_id'], options['question_code'], options)

         if data.present? && data[:dataset].present?
          # save dataset title
          output[:title] = data[:dataset][:title]

          # set permalink to dataset
          permalink = Dataset.get_slug(options['dataset_id'])
          permalink = options['dataset_id'] if permalink.blank?

          # create link to dashboard
          output[:dashboard_link] = use_admin_link.to_s == 'true' ? dataset_url(permalink) : explore_data_dashboard_url(permalink)

          # create link to this item
          options['id'] = permalink
          output[:id] = options['id']
          options['from_embed'] = true
          output[:explore_link] = use_admin_link.to_s == 'true' ? explore_dataset_url(options) : explore_data_show_url(options)
        end
      elsif options['time_series_id'].present?
        output[:type] = 'time_series'

        data = Api::V2.time_series_analysis(options['time_series_id'], options['question_code'], options)

        if data.present? && data[:time_series].present?
          # save dataset title
          output[:title] = data[:time_series][:title]

          # set permalink to dataset
          permalink = TimeSeries.get_slug(options['time_series_id'])
          permalink = options['time_series_id'] if permalink.blank?

          # create link to dashboard
          output[:dashboard_link] = use_admin_link.to_s == 'true' ? time_series_url(path) : explore_time_series_dashboard_url(permalink)

          # create link to this item
          options['id'] = permalink
          output[:id] = options['id']
          options['from_embed'] = true
          output[:explore_link] = use_admin_link.to_s == 'true' ? explore_time_series_url(options) : explore_time_series_show_url(options)
        end
      end

      # check if errors exist
      output[:error] = data[:error].present?

      # record if data exists
      output[:has_data] = data[:results].present? &&
        ((data[:results][:analysis].present? && data[:results][:analysis].length > 0) ||
         (data[:results][:filter_analysis].present? && data[:results][:filter_analysis].length > 0)) if !output[:error]

      if !output[:error] && output[:has_data]
        # save data to so can be used for charts
        output[:js] = {}

        output[:js][:json_data] = data
        output[:js][:visual_type] = output[:visual_type]
        # save values of filters so can choose correct chart/map to show
        output[:js][:broken_down_by_value] = options['broken_down_by_value'] if options['broken_down_by_value'].present? # only present if doing maps
        output[:js][:filtered_by_value] = options['filtered_by_value'] if options['filtered_by_value'].present?
      end

    end
logger.debug "======= output js = #{output[:js]}"

    return output
  end

  # based on the highlight visual types, load the correct js files
  def load_highlight_assets(embed_ids)
    embed_ids = [embed_ids] if embed_ids.class != Array
    visual_types = []
    dataset_ids = []
    # decode each embed id and get the visual types
    embed_ids.each do |embed_id|
      begin
        options = Rack::Utils.parse_query(Base64.urlsafe_decode64(embed_id))
        visual_types << options['visual_type']
        if options['dataset_id'].present?
          dataset_ids << options['dataset_id']
        end
      end
    end

    # if the visual is a chart, include the highcharts file
    # if the visual is a map, include the highmaps file
    if visual_types.index('chart').present?
      @js.push('highcharts.js')
    end
    if visual_types.index('map').present?
      @js.push('highcharts.js', 'highcharts-map.js')

      if dataset_ids.present?
        # have to get the shape file url for this dataset
        @shapes_url = []
        dataset_ids.uniq.each do |dataset_id|
          @shapes_url << Dataset.shape_file_url(dataset_id)
        end
      end
    end
    @js.push('highcharts-exporting.js')

    @css.push('embed.css', 'explore.css')
    @js.push('embed.js', 'explore.js')

    gon.generate_highlights_url = generate_highlights_path
    set_gon_highcharts
  end

  def set_gon_highcharts
    gon.highcharts_context_title = I18n.t('highcharts.context_title')
    gon.highcharts_png = I18n.t('highcharts.png')
    gon.highcharts_jpg = I18n.t('highcharts.jpg')
    gon.highcharts_pdf = I18n.t('highcharts.pdf')
    gon.highcharts_svg = I18n.t('highcharts.svg')

    gon.add_highlight_text = I18n.t('helpers.links.add_highlight')
    gon.highlight_description_chart_text = I18n.t('helpers.links.highlight_description_chart')
    gon.embed_chart_text = I18n.t('helpers.links.embed_chart')
    gon.delete_highlight_text = I18n.t('helpers.links.delete_highlight')
    gon.description_highlight_text = I18n.t('helpers.links.description_highlight')
    gon.confirm_text = I18n.t('helpers.links.confirm')

    gon.disclaimer_text = I18n.t('app.menu.disclaimer')
    gon.disclaimer_link = disclaimer_url
  end

  def set_gon_datatables
    gon.datatable_search = I18n.t('datatable.search')
    gon.datatable_copy_title = I18n.t('datatable.copy.title')
    gon.datatable_copy_tooltip = I18n.t('datatable.copy.tooltip')
    gon.datatable_csv_title = I18n.t('datatable.csv.title')
    gon.datatable_csv_tooltip = I18n.t('datatable.csv.tooltip')
    gon.datatable_xls_title = I18n.t('datatable.xls.title')
    gon.datatable_xls_tooltip = I18n.t('datatable.xls.tooltip')
    gon.datatable_pdf_title = I18n.t('datatable.pdf.title')
    gon.datatable_pdf_tooltip = I18n.t('datatable.pdf.tooltip')
    gon.datatable_print_title = I18n.t('datatable.print.title')
    gon.datatable_print_tooltip = I18n.t('datatable.print.tooltip')
  end


  #######################
  #######################
	def render_not_found(exception)
		ExceptionNotifier::Notifier
		  .exception_notification(request.env, exception)
		  .deliver
		render :file => "#{Rails.root}/public/404.html", :status => 404
	end

	def render_error(exception)
		ExceptionNotifier::Notifier
		  .exception_notification(request.env, exception)
		  .deliver
		render :file => "#{Rails.root}/public/500.html", :status => 500
	end
  def per_page
    return PER_PAGE_COUNT
  end

end

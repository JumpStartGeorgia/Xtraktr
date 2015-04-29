class ApplicationController < ActionController::Base
  layout 'app'
  protect_from_forgery

	before_filter :set_locale
	before_filter :is_browser_supported?
	before_filter :preload_global_variables
	before_filter :initialize_gon
	before_filter :store_location

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
    # indicate that whether login should allow local and omniauth or just locale
	  @enable_omniauth = false

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

    # show subnav bar
    @show_subnav_navbar = false
  end

  # show the subnavbar
  # this is called from before_filters in controllers
  def set_subnavbar
    @show_subnav_navbar = true
  end

	def initialize_gon
		gon.set = true
		gon.highlight_first_form_field = false
    gon.app_api_key = @app_api_key

		if I18n.locale == :ka
		  gon.datatable_i18n_url = "/datatable_ka.txt"
		else
		  gon.datatable_i18n_url = ""
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
		if session[:previous_urls].first != request.fullpath && 
        params[:format] != 'js' && params[:format] != 'json' && !request.xhr? &&
        request.fullpath.index("/users/").nil?
        
	    session[:previous_urls].unshift request.fullpath
    elsif session[:previous_urls].first != request.fullpath &&
       request.xhr? && !request.fullpath.index("/users/").nil? &&
       params[:return_url].present?
       
      session[:previous_urls].unshift params[:return_url]
		end

		session[:previous_urls].pop if session[:previous_urls].count > 1
    #Rails.logger.debug "****************** prev urls session = #{session[:previous_urls]}"
	end
	
  def clean_filename(filename)
    filename.strip.latinize.to_ascii.gsub(' ', '_').gsub(/[\\ \/ \: \* \? \" \< \> \| \, \. ]/,'')
  end


  # add options to show the dataset nav bar
  def add_dataset_nav_options(options={})
    show_title = options[:show_title].nil? ? true : options[:show_title]
    set_url = options[:set_url].nil? ? true : options[:set_url]

    @css.push("datasets.css")
    @dataset_url = dataset_path(@dataset) if set_url
    @is_dataset_admin = true
    
    @show_title = show_title
  end

  # add options to show the time series nav bar
  def add_time_series_nav_options(options={})
    show_title = options[:show_title].nil? ? true : options[:show_title]
    set_url = options[:set_url].nil? ? true : options[:set_url]

    @css.push("time_series.css")
    @time_series_url = time_series_path(@time_series) if set_url
    @is_time_series_admin = true
    
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
  def explore_data_generator(dataset)
    # if the language parameter exists and it is valid, use it instead of the default current_locale
    if params[:language].present? && dataset.languages.include?(params[:language])
      dataset.current_locale = params[:language]
    end

    # the questions for cross tab can only be those that have code answers and are not excluded
    @questions = dataset.questions.for_analysis

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
        if dataset.is_mappable?
          @shapes_url = dataset.js_shapefile_url_path
        end

        # add the required assets
        @css.push('bootstrap-select.min.css', "explore.css", "datasets.css")
        @js.push('bootstrap-select.min.js', "explore_data.js", 'highcharts.js', 'highcharts-map.js', 'highcharts-exporting.js')

        # record javascript variables
        gon.hover_region = I18n.t('explore_data.hover_region')
        gon.na = I18n.t('explore_data.na')
        gon.percent = I18n.t('explore_data.percent')
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
        gon.highcharts_context_title = I18n.t('highcharts.context_title')
        gon.highcharts_png = I18n.t('highcharts.png')
        gon.highcharts_jpg = I18n.t('highcharts.jpg')
        gon.highcharts_pdf = I18n.t('highcharts.pdf')
        gon.highcharts_svg = I18n.t('highcharts.svg')

        gon.explore_data = true
        gon.dataset_id = params[:id]
        gon.api_dataset_analysis_path = api_v1_dataset_analysis_path

#        render layout: 'explore_data'
      } 
      # format.js{
#         # get the data
#         options = {}
#         options[:broken_down_by_code] = @broken_down_by_code if @broken_down_by_code.present?
#         options[:filtered_by_code] = @filtered_by_code if @filtered_by_code.present?
#         options[:language] = params[:language] if params[:language].present?
#         options[:can_exclude] = params[:can_exclude].to_bool if params[:can_exclude].present?
#         options[:chart_formatted_data] = params[:chart_formatted_data].to_bool if params[:chart_formatted_data].present?
#         options[:map_formatted_data] = params[:map_formatted_data].to_bool if params[:map_formatted_data].present?

#         @data = nil
#         if @questions.present?
#           # if @broken_down_by_code has data, then this is a crosstab,
#           # else this is just a single variable lookup
#           @data = ApiV1.dataset_analysis(dataset.id, @question_code, options)
#           if @broken_down_by_code.present?

#             @data[:title] = {}
#             @data[:title][:html] = build_data_crosstab_title_html(@data[:row_question], @data[:column_question], @filtered_by_code, @data[:total_responses])
#             @data[:title][:text] = build_data_crosstab_title_text(@data[:row_question], @data[:column_question], @filtered_by_code, @data[:total_responses])
#             # create special map titles so filter of column can be shown in title
#             # test to see which variable is mappable - that one must go in as the row for the map title
#             row_index = @questions.select{|x| x.code == params[:question_code] && x.is_mappable?}
#             if row_index.present?
#               @data[:title][:map_html] = build_data_crosstab_map_title_html(@data[:row_question], @data[:column_question], @filtered_by_code, @data[:total_responses])
#               @data[:title][:map_text] = build_data_crosstab_map_title_text(@data[:row_question], @data[:column_question], @filtered_by_code, @data[:total_responses])
#             else
#               @data[:title][:map_html] = build_data_crosstab_map_title_html(@data[:column_question], @data[:row_question], @filtered_by_code, @data[:total_responses])
#               @data[:title][:map_text] = build_data_crosstab_map_title_text(@data[:column_question], @data[:row_question], @filtered_by_code, @data[:total_responses])
#             end
#           else
            
#             @data[:title] = {}
#             @data[:title][:html] = build_data_onevar_title_html(@data[:row_question], @filtered_by_code, @data[:total_responses])
#             @data[:title][:text] = build_data_onevar_title_text(@data[:row_question], @filtered_by_code, @data[:total_responses])
#             @data[:title][:map_html] = @data[:title][:html]
#             @data[:title][:map_text] = @data[:title][:text]
#           end
#           @data[:subtitle] = {}
#           @data[:subtitle][:html] = build_data_subtitle_html(@data[:total_responses])
#           @data[:subtitle][:text] = build_data_subtitle_text(@data[:total_responses])
#         end

# #        logger.debug "/////////////////////////// #{@data}"

#         status = @data.present? ? :ok : :unprocessable_entity
#         render json: @data.to_json, status: status

#       }
    end   
  end

  # def build_data_crosstab_title_html(row, col, filter, total)
  #   title = t('explore_data.crosstab.html.title', :row => row, :col => col)
  #   if filter.present?
  #     title << t('explore_data.crosstab.html.title_filter', :variable => filter[:name], :value => filter[:answer] )
  #   end
  #   return title.html_safe
  # end 

  # def build_data_crosstab_title_text(row, col, filter, total)
  #   title = t('explore_data.crosstab.text.title', :row => row, :col => col)
  #   if filter.present?
  #     title << t('explore_data.crosstab.text.title_filter', :variable => filter[:name], :value => filter[:answer] )
  #   end
  #   return title
  # end 

  # def build_data_crosstab_map_title_html(row, col, filter, total)
  #   title = t('explore_data.crosstab.html.map.title', :row => row)
  #   title << t('explore_data.crosstab.html.map.title_col', :col => col)
  #   if filter.present?
  #     title << t('explore_data.crosstab.html.map.title_filter', :variable => filter[:name], :value => filter[:answer] )
  #   end
  #   return title.html_safe
  # end 

  # def build_data_crosstab_map_title_text(row, col, filter, total)
  #   title = t('explore_data.crosstab.text.map.title', :row => row)
  #   title << t('explore_data.crosstab.text.map.title_col', :col => col)
  #   if filter.present?
  #     title << t('explore_data.crosstab.text.map.title_filter', :variable => filter[:name], :value => filter[:answer] )
  #   end
  #   return title
  # end 

  # def build_data_onevar_title_html(row, filter, total)
  #   title = t('explore_data.onevar.html.title', :row => row)
  #   if filter.present?
  #     title << t('explore_data.onevar.html.title_filter', :variable => filter[:name], :value => filter[:answer] )
  #   end
  #   return title.html_safe
  # end 

  # def build_data_onevar_title_text(row, filter, total)
  #   title = t('explore_data.onevar.text.title', :row => row)
  #   if filter.present?
  #     title << t('explore_data.onevar.text.title_filter', :variable => filter[:name], :value => filter[:answer] )
  #   end
  #   return title
  # end 

  # def build_data_subtitle_html(total)
  #   title = "<br /> <span class='total_responses'>"
  #   title << t('explore_data.subtitle.html', :num => view_context.number_with_delimiter(total))
  #   title << "</span>"
  #   return title.html_safe
  # end 

  # def build_data_subtitle_text(total)
  #   return t('explore_data.subtitle.text', :num => view_context.number_with_delimiter(total))
  # end 
	

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
        @css.push('bootstrap-select.min.css', "explore.css", "time_series.css")
        @js.push('bootstrap-select.min.js', "explore_time_series.js", 'highcharts.js', 'highcharts-exporting.js')

        # record javascript variables
        gon.na = I18n.t('explore_time_series.na')
        gon.percent = I18n.t('explore_time_series.percent')
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
        gon.highcharts_context_title = I18n.t('highcharts.context_title')
        gon.highcharts_png = I18n.t('highcharts.png')
        gon.highcharts_jpg = I18n.t('highcharts.jpg')
        gon.highcharts_pdf = I18n.t('highcharts.pdf')
        gon.highcharts_svg = I18n.t('highcharts.svg')

        gon.explore_time_series = true
        gon.time_series_id = params[:id]
        gon.api_time_series_analysis_path = api_v1_time_series_analysis_path

        # render layout: 'explore_time_series'
      } 
      # format.js{
      #   # get the data
      #   options = {}
      #   options[:filtered_by_code] = @filtered_by_code if @filtered_by_code.present?
      #   options[:can_exclude] = params[:can_exclude].to_bool if params[:can_exclude].present?

      #   @data = nil
      #   if @questions.present?
      #     @data = time_series.data_onevar_analysis(@question_code, options)
          
      #     @data[:title] = {}
      #     @data[:title][:html] = build_time_series_onevar_title_html(@data[:row_question], @filter, @data[:total_responses])
      #     @data[:title][:text] = build_time_series_onevar_title_text(@data[:row_question], @filter, @data[:total_responses])
      #     @data[:title][:map_html] = @data[:title][:html]
      #     @data[:title][:map_text] = @data[:title][:text]

      #     @data[:subtitle] = {}
      #     @data[:subtitle][:html] = build_time_series_subtitle_html(@data[:column_answers], @data[:total_responses])
      #     @data[:subtitle][:text] = build_time_series_subtitle_text(@data[:column_answers], @data[:total_responses])
      #   end

      #   logger.debug "/////////////////////////// #{@data}"

      #   status = @data.present? ? :ok : :unprocessable_entity
      #   render json: @data.to_json, status: :ok

      # }
    end   
  end

  # def build_time_series_onevar_title_html(row, filter, total)
  #   title = t('explore_time_series.onevar.html.title', :row => row)
  #   if filter.present?
  #     title << t('explore_time_series.onevar.html.title_filter', :variable => filter[:name], :value => filter[:answer] )
  #   end
  #   return title.html_safe
  # end 

  # def build_time_series_onevar_title_text(row, filter, total)
  #   title = t('explore_time_series.onevar.text.title', :row => row)
  #   if filter.present?
  #     title << t('explore_time_series.onevar.text.title_filter', :variable => filter[:name], :value => filter[:answer] )
  #   end
  #   return title
  # end 

  # def build_time_series_subtitle_html(datasets, totals)
  #   title = "<br /> <span class='total_responses'>"
  #   num = []
  #   (0..datasets.length-1).each do |index|
  #     num << "#{datasets[index]}: <span class='number'>#{view_context.number_with_delimiter(totals[index])}</span>"
  #   end
  #   title << t('explore_time_series.subtitle.html', :num => num.join('; '))
  #   title << "</span>"
  #   return title.html_safe
  # end 

  # def build_time_series_subtitle_text(datasets, totals)
  #   num = []
  #   (0..datasets.length-1).each do |index|
  #     num << "#{datasets[index]}: #{view_context.number_with_delimiter(totals[index])}"
  #   end
  #   return t('explore_time_series.subtitle.text', :num => num.join('; '))
  # end 


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

end

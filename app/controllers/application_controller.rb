class ApplicationController < ActionController::Base
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
		user_agent = UserAgent.parse(request.user_agent)
logger.debug "////////////////////////// BROWSER = #{user_agent}"
#		if SUPPORTED_BROWSERS.any? { |browser| user_agent < browser }
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
	  @enable_omniauth = true

    # for loading extra css/js files    
    @css = []
    @js = []
  end

	def initialize_gon
		gon.set = true
		gon.highlight_first_form_field = true

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
	
  # add in required content for translations if none provided
  # - if default locale does not have translations, use first trans that does as default
  def add_missing_translation_content(ary_trans)
    if ary_trans.present?
      default_trans = ary_trans.select{|x| x.locale == I18n.default_locale.to_s}.first
  
      if default_trans.blank? || !default_trans.required_data_provided?
        # default locale does not have data so get first trans that does have data
        ary_trans.each do |trans|
          if trans.required_data_provided?
            default_trans = trans
            break
          end
        end
      end

      if default_trans.present? && default_trans.required_data_provided?
        ary_trans.each do |trans|
          if trans.locale != default_trans.locale && !trans.required_data_provided?
            # add required content from default locale trans
            trans.add_required_data(default_trans)
          end
        end
      end
    end
  end

  # add options to show the dataset nav bar
  def add_dataset_nav_options(options={})
    show_title = options[:show_title].nil? ? true : options[:show_title]
    set_url = options[:set_url].nil? ? true : options[:set_url]

    @css.push("datasets.css")
    @dataset_url = dataset_path(@dataset) if set_url
    @is_admin = true
    
    @show_title = show_title
  end

  # add options to show the time series nav bar
  def add_time_series_nav_options(options={})
    show_title = options[:show_title].nil? ? true : options[:show_title]
    set_url = options[:set_url].nil? ? true : options[:set_url]

    @css.push("time_series.css")
    @time_series_url = time_series_path(@time_series) if set_url
    @is_admin = true
    
    @show_title = show_title
  end


  # set variables need for the tabbed translation forms
  def set_tabbed_translation_form_settings
    @languages = Language.sorted
    @css.push('tabbed_translation_form.css', 'select2.css')
    @js.push('tabbed_translation_form.js', 'select2/select2.min.js')
    gon.tinymce_options = Hash[TinyMCE::Rails.configuration['default'].options.map{|(k,v)| [k.to_s,v.class == Array ? v.join(',') : v]}]
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
      @row = @questions.map{|x| x.code}.sample
      @col = nil
      @filter = nil

      # check to make sure row and col param is in list of questions, if provided
      if params[:row].present? && @questions.index{|x| x.code == params[:row]}.present?
        @row = params[:row]
      end
      if params[:col].present? && @questions.index{|x| x.code == params[:col]}.present?
        @col = params[:col]
      end

      # check for valid filter values
      if params[:filter_variable].present? && params[:filter_value].present? &&
        q = @questions.select{|x| x.code.to_s == params[:filter_variable]}.first
        a = q.answers.with_value(params[:filter_value]) if q.present?
        
        if q.present? && a.present?
          @filter = {code: params[:filter_variable], value: params[:filter_value], name: q.text, answer: a.text }
        end
      end
    end

    respond_to do |format|
      format.html{
        # load the shapes if needed
        if dataset.is_mappable?
          @shapes_url = dataset.js_shapefile_url_path
        end

        # add the required assets
        @css.push('bootstrap-select.min.css', "explore_data.css", "datasets.css")
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
      } 
      format.js{
        # get the data
        options = {}
        options[:filter] = @filter if @filter.present?
        options[:exclude_dkra] = params[:exclude_dkra].to_bool if params[:exclude_dkra].present?

        @data = nil
        if @questions.present?
          # if @col has data, then this is a crosstab,
          # else this is just a single variable lookup
          if @col.present?
            @data = dataset.data_crosstab_analysis(@row, @col, options)

            @data[:title] = {}
            @data[:title][:html] = build_data_crosstab_title_html(@data[:row_question], @data[:column_question], @filter, @data[:total_responses])
            @data[:title][:text] = build_data_crosstab_title_text(@data[:row_question], @data[:column_question], @filter, @data[:total_responses])
            # create special map titles so filter of column can be shown in title
            # test to see which variable is mappable - that one must go in as the row for the map title
            row_index = @questions.select{|x| x.code == params[:row] && x.is_mappable?}
            if row_index.present?
              @data[:title][:map_html] = build_data_crosstab_map_title_html(@data[:row_question], @data[:column_question], @filter, @data[:total_responses])
              @data[:title][:map_text] = build_data_crosstab_map_title_text(@data[:row_question], @data[:column_question], @filter, @data[:total_responses])
            else
              @data[:title][:map_html] = build_data_crosstab_map_title_html(@data[:column_question], @data[:row_question], @filter, @data[:total_responses])
              @data[:title][:map_text] = build_data_crosstab_map_title_text(@data[:column_question], @data[:row_question], @filter, @data[:total_responses])
            end
          else
            @data = dataset.data_onevar_analysis(@row, options)
            
            @data[:title] = {}
            @data[:title][:html] = build_data_onevar_title_html(@data[:row_question], @filter, @data[:total_responses])
            @data[:title][:text] = build_data_onevar_title_text(@data[:row_question], @filter, @data[:total_responses])
            @data[:title][:map_html] = @data[:title][:html]
            @data[:title][:map_text] = @data[:title][:text]
          end
          @data[:subtitle] = {}
          @data[:subtitle][:html] = build_data_subtitle_html(@data[:total_responses])
          @data[:subtitle][:text] = build_data_subtitle_text(@data[:total_responses])
        end

#        logger.debug "/////////////////////////// #{@data}"

        status = @data.present? ? :ok : :unprocessable_entity
        render json: @data.to_json, status: :ok

      }
    end   
  end

  def build_data_crosstab_title_html(row, col, filter, total)
    title = t('explore_data.crosstab.html.title', :row => row, :col => col)
    if filter.present?
      title << t('explore_data.crosstab.html.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title.html_safe
  end 

  def build_data_crosstab_title_text(row, col, filter, total)
    title = t('explore_data.crosstab.text.title', :row => row, :col => col)
    if filter.present?
      title << t('explore_data.crosstab.text.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title
  end 

  def build_data_crosstab_map_title_html(row, col, filter, total)
    title = t('explore_data.crosstab.html.map.title', :row => row)
    title << t('explore_data.crosstab.html.map.title_col', :col => col)
    if filter.present?
      title << t('explore_data.crosstab.html.map.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title.html_safe
  end 

  def build_data_crosstab_map_title_text(row, col, filter, total)
    title = t('explore_data.crosstab.text.map.title', :row => row)
    title << t('explore_data.crosstab.text.map.title_col', :col => col)
    if filter.present?
      title << t('explore_data.crosstab.text.map.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title
  end 

  def build_data_onevar_title_html(row, filter, total)
    title = t('explore_data.onevar.html.title', :row => row)
    if filter.present?
      title << t('explore_data.onevar.html.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title.html_safe
  end 

  def build_data_onevar_title_text(row, filter, total)
    title = t('explore_data.onevar.text.title', :row => row)
    if filter.present?
      title << t('explore_data.onevar.text.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title
  end 

  def build_data_subtitle_html(total)
    title = "<br /> <span class='total_responses'>"
    title << t('explore_data.subtitle.html', :num => view_context.number_with_delimiter(total))
    title << "</span>"
    return title.html_safe
  end 

  def build_data_subtitle_text(total)
    return t('explore_data.subtitle.text', :num => view_context.number_with_delimiter(total))
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
      @row = @questions.map{|x| x.code}.sample
      @filter = nil

      # check to make sure row param is in list of questions, if provided
      if params[:row].present? && @questions.index{|x| x.code == params[:row]}.present?
        @row = params[:row]
      end

      # check for valid filter values
      if params[:filter_variable].present? && params[:filter_value].present? &&
        q = @questions.select{|x| x.code.to_s == params[:filter_variable]}.first
        a = q.answers.with_value(params[:filter_value]) if q.present?
        
        if q.present? && a.present?
          @filter = {code: params[:filter_variable], value: params[:filter_value], name: q.text, answer: a.text }
        end
      end
    end

    respond_to do |format|
      format.html{
        # add the required assets
        @css.push('bootstrap-select.min.css', "explore_time_series.css", "time_series.css")
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
      } 
      format.js{
        # get the data
        options = {}
        options[:filter] = @filter if @filter.present?
        options[:exclude_dkra] = params[:exclude_dkra].to_bool if params[:exclude_dkra].present?

        @data = nil
        if @questions.present?
          @data = time_series.data_onevar_analysis(@row, options)
          
          @data[:title] = {}
          @data[:title][:html] = build_time_series_onevar_title_html(@data[:row_question], @filter, @data[:total_responses])
          @data[:title][:text] = build_time_series_onevar_title_text(@data[:row_question], @filter, @data[:total_responses])
          @data[:title][:map_html] = @data[:title][:html]
          @data[:title][:map_text] = @data[:title][:text]

          @data[:subtitle] = {}
          @data[:subtitle][:html] = build_time_series_subtitle_html(@data[:column_answers], @data[:total_responses])
          @data[:subtitle][:text] = build_time_series_subtitle_text(@data[:column_answers], @data[:total_responses])
        end

        logger.debug "/////////////////////////// #{@data}"

        status = @data.present? ? :ok : :unprocessable_entity
        render json: @data.to_json, status: :ok

      }
    end   
  end

  def build_time_series_onevar_title_html(row, filter, total)
    title = t('explore_time_series.onevar.html.title', :row => row)
    if filter.present?
      title << t('explore_time_series.onevar.html.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title.html_safe
  end 

  def build_time_series_onevar_title_text(row, filter, total)
    title = t('explore_time_series.onevar.text.title', :row => row)
    if filter.present?
      title << t('explore_time_series.onevar.text.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title
  end 

  def build_time_series_subtitle_html(datasets, totals)
    title = "<br /> <span class='total_responses'>"
    num = []
    (0..datasets.length-1).each do |index|
      num << "#{datasets[index]}: <span class='number'>#{view_context.number_with_delimiter(totals[index])}</span>"
    end
    title << t('explore_time_series.subtitle.html', :num => num.join('; '))
    title << "</span>"
    return title.html_safe
  end 

  def build_time_series_subtitle_text(datasets, totals)
    num = []
    (0..datasets.length-1).each do |index|
      num << "#{datasets[index]}: #{view_context.number_with_delimiter(totals[index])}"
    end
    return t('explore_time_series.subtitle.text', :num => num.join('; '))
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

end

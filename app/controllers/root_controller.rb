class RootController < ApplicationController
  before_filter :set_subnavbar, only: [:explore_data_dashboard, :explore_data_show, :explore_time_series_dashboard, :explore_time_series_show]

  def index
    @datasets = Dataset.is_public.recent.sorted.limit(5)

    @time_series = TimeSeries.is_public.recent.sorted.limit(5) if @is_xtraktr

    @css.push('root.css')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def instructions
    @page_content = PageContent.by_name('instructions')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def contact
    @page_content = PageContent.by_name('contact')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def disclaimer
    @page_content = PageContent.by_name('disclaimer')

    respond_to do |format|
      format.html # index.html.erb
    end
  end


  def explore_data
    @datasets = Dataset.is_public

    # add search
    if params[:q].present?
      @datasets = @datasets.search(params[:q])
    end
    # add sort
    if params[:sort].present?
      case params[:sort].downcase
        when 'publish'
          @datasets = @datasets.sorted_public_at
        when 'release'
          @datasets = @datasets.sorted_released_at
        when 'title'
          @datasets = @datasets.sorted_title
      end
    else
      @datasets = @datasets.sorted_title
    end
    # add category
    if params[:category].present?
      @datasets = @datasets.categorize(params[:category])
    end

    @datasets = Kaminari.paginate_array(@datasets).page(params[:page]).per(per_page)
    
    data = { d: (render_to_string "root/_explore_data_datasets", :layout => false) }
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: data }
    end    
  end
  
  def explore_data_dashboard
    @dataset = Dataset.is_public.find_by(id: params[:id])

    if @dataset.blank?
      redirect_to explore_data_path, :notice => t('app.msgs.does_not_exist')
    else
      # if the language parameter exists and it is valid, use it instead of the default current_locale
      if params[:language].present? && @dataset.languages.include?(params[:language])
        @dataset.current_locale = params[:language]
      end

      @license = PageContent.by_name('license')

      @css.push("dashboard.css")
      @js.push("live_search.js")

      respond_to do |format|
        format.html # index.html.erb
      end
    end
  end
  
  def explore_data_show
    @dataset = Dataset.is_public.find_by(id: params[:id])

    if @dataset.blank?
      redirect_to explore_data_path, :notice => t('app.msgs.does_not_exist')
    else
      @show_title = false
      @is_admin = false
      @dataset_url = explore_data_show_path(@dataset)

      # this method is in application_controller
      # and gets all of the required information
      # and responds appropriately to html or js
      explore_data_generator(@dataset)
    end
  end
  


  def explore_time_series
    @time_series = TimeSeries.is_public

    # add search
    if params[:q].present?
      @time_series = @time_series.search(params[:q])
    end
    # add sort
    if params[:sort].present?
      case params[:sort].downcase
        when 'public'
          @time_series = @time_series.sorted_public_at
        when 'title'
          @time_series = @time_series.sorted_title
      end
    else
      @time_series = @time_series.sorted_title
    end
    # add category
    if params[:category].present?

    end


    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  def explore_time_series_dashboard
    @time_series = TimeSeries.is_public.find_by(id: params[:id])

    if @time_series.blank?
      redirect_to explore_time_series_path, :notice => t('app.msgs.does_not_exist')
    else

      # if the language parameter exists and it is valid, use it instead of the default current_locale
      if params[:language].present? && @time_series.languages.include?(params[:language])
        @time_series.current_locale = params[:language]
      end

      @license = PageContent.by_name('license')

      @css.push("dashboard.css")
      @js.push("live_search.js")

      respond_to do |format|
        format.html # index.html.erb
      end
    end
  end
  

  def explore_time_series_show
    @time_series = TimeSeries.is_public.find_by(id: params[:id])

    if @time_series.blank?
      redirect_to explore_time_series_path, :notice => t('app.msgs.does_not_exist')
    else
      @show_title = false
      @is_admin = false
      @time_series_url = explore_time_series_show_path(@time_series)

      # this method is in application_controller
      # and gets all of the required information
      # and responds appropriately to html or js
      explore_time_series_generator(@time_series)
    end
  end
  

  def private_share
    @dataset = Dataset.by_private_key(params[:id])

    if @dataset.blank?
      redirect_to root_path, :notice => t('app.msgs.does_not_exist')
    elsif @dataset.public?
      redirect_to explore_data_show_path(@dataset)      
    else
      @is_admin = false
      @dataset_url = private_share_path(@dataset.private_share_key)
      gon.explore_data = true
      gon.api_dataset_analysis_path = api_v1_dataset_analysis_path

      # this method is in application_controller
      # and gets all of the required information
      # and responds appropriately to html or js
      explore_data_generator(@dataset)
    end
  end

  def download_request
    sign_in = user_signed_in?
    data = { agreement: sign_in }
    @file_id = params[:id]
    @file_type = params[:type]
    if sign_in && current_user.agreement(@file_id)
      mapper = FileMapper.create({ file: @file_id, type: @file_type })
      data[:url] = "/#{I18n.locale}/download/#{mapper.key}"
    else
      @mod = Agreement.new      
      data[:form] = render_to_string "agreement/_form", :layout => false
    end    
    respond_to do |format|
      format.json { render json: data }
    end
  end
  def download
    begin      
     mapper = FileMapper.find_by(key: params[:id])
     file = Dataset.find(mapper.file)
     mapper.destroy
     send_file  file.datafile.path , :filename => file.title.gsub(' ', '_') + File.extname(file.datafile.original_filename),
  :type => 'application/octet-stream'
    rescue
      render file: "#{Rails.root}/public/404.html", layout: false, status: 404
    end
  end
  
end

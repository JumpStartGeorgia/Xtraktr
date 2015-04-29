class RootController < ApplicationController
  before_filter :set_subnavbar, only: [:explore_data_dashboard, :explore_data_show, :explore_time_series_dashboard, :explore_time_series_show]

  def index
    @datasets = Dataset.is_public.recent.sorted.limit(5)

    @time_series = TimeSeries.is_public.recent.sorted.limit(5) if @is_xtraktr

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
    @datasets = Dataset.is_public.sorted

    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  def explore_data_dashboard
    @dataset = Dataset.is_public.find_by(id: params[:id])

    if @dataset.blank?
      redirect_to explore_data_path, :notice => t('app.msgs.does_not_exist')
    else
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
    @time_series = TimeSeries.is_public.sorted

    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  def explore_time_series_dashboard
    @time_series = TimeSeries.is_public.find_by(id: params[:id])

    if @time_series.blank?
      redirect_to explore_time_series_path, :notice => t('app.msgs.does_not_exist')
    else
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
  
end

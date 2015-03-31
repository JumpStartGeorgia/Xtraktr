class TimeSeriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, User::ROLES[:user])
  end

  layout "explore_time_series"

  # GET /time_series
  # GET /time_series.json
  def index
    @time_series = TimeSeries.by_user(current_user.id).sorted

    @css.push("time_series.css")
    @js.push("search.js")

    respond_to do |format|
      format.html { render layout: 'application' }
      format.json { render json: @time_series }
    end
  end

  # GET /time_series/1
  # GET /time_series/1.json
  def show
    @time_series = TimeSeries.by_id_for_user(params[:id], current_user.id)

    if @time_series.blank?
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_path(:locale => I18n.locale)
      return
    else
      add_time_series_nav_options

      @css.push("dashboard_time_series.css")
      @js.push("live_search.js")

      respond_to do |format|
        format.html # index.html.erb
      end
    end
  end
  

  # GET /time_series/1
  # GET /time_series/1.json
  def explore
    @time_series = TimeSeries.by_id_for_user(params[:id], current_user.id)

    if @time_series.blank?
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_path(:locale => I18n.locale)
      return
    else
      add_time_series_nav_options(show_title: false)

      gon.explore_time_series = true
      gon.explore_time_series_ajax_path = explore_time_series_path(:format => :js)

      # this method is in application_controller
      # and gets all of the required information
      # and responds appropriately to html or js
      explore_time_series_generator(@time_series)
    end

  end

  # GET /time_series/new
  # GET /time_series/new.json
  def new
    @time_series = TimeSeries.new
    @datasets = Dataset.by_user(current_user.id).only_id_title_languages.sorted

    add_time_series_nav_options(set_url: false)

    set_tabbed_translation_form_settings

    @js.push("time_series.js", 'cocoon.js')

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @time_series }
    end
  end

  # GET /time_series/1/edit
  def edit
    @time_series = TimeSeries.by_id_for_user(params[:id], current_user.id)
  
    if @time_series.present?
      @datasets = Dataset.by_user(current_user.id).only_id_title_languages.sorted

      # add the required assets
      @css.push("time_series.css")
      @js.push("time_series.js", 'cocoon.js')

      add_time_series_nav_options()

      set_tabbed_translation_form_settings
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_path(:locale => I18n.locale)
      return
    end
end

  # POST /time_series
  # POST /time_series.json
  def create
    @time_series = TimeSeries.new(params[:time_series])

    respond_to do |format|
      if @time_series.save
        format.html { redirect_to time_series_questions_path(@time_series), notice: t('app.msgs.success_created', :obj => t('mongoid.models.time_series')) }
        format.json { render json: @time_series, status: :created, location: @time_series }
      else
        @datasets = Dataset.by_user(current_user.id).only_id_title_languages.sorted

        # add the required assets
        @js.push("time_series.js", 'cocoon.js')

        add_time_series_nav_options({show_title: false, set_url: false})

        set_tabbed_translation_form_settings

        format.html { render action: "new" }
        format.json { render json: @time_series.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /time_series/1
  # PUT /time_series/1.json
  def update
    @time_series = TimeSeries.by_id_for_user(params[:id], current_user.id)

    if @time_series.present?

      @time_series.assign_attributes(params[:time_series])

      respond_to do |format|
        if @time_series.save
          format.html { redirect_to @time_series, notice: t('app.msgs.success_updated', :obj => t('mongoid.models.time_series')) }
          format.json { head :no_content }
        else
          @datasets = Dataset.by_user(current_user.id).only_id_title_languages.sorted

          # add the required assets
          @js.push("time_series.js", 'cocoon.js')

          add_time_series_nav_options()

          set_tabbed_translation_form_settings

          format.html { render action: "edit" }
          format.json { render json: @time_series.errors, status: :unprocessable_entity }
        end
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_path(:locale => I18n.locale)
      return
    end
  end

  # DELETE /time_series/1
  # DELETE /time_series/1.json
  def destroy
    @time_series = TimeSeries.by_id_for_user(params[:id], current_user.id)
    if @time_series.present?
      @time_series.destroy

      respond_to do |format|
        format.html { redirect_to time_series_index_url }
        format.json { head :no_content }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_path(:locale => I18n.locale)
      return
    end
  end



  # automatically assign matching questions
  def automatically_assign_questions
    @time_series = TimeSeries.by_id_for_user(params[:id], current_user.id)
    if @time_series.present?
      count = @time_series.automatically_assign_questions

      respond_to do |format|
        format.html { redirect_to time_series_questions_path(@time_series), notice: t('app.msgs.time_series_automatic_match', :count => count) }
        format.json { head :no_content }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_path(:locale => I18n.locale)
      return
    end
  end
end

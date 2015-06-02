class TimeSeriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, User::ROLES[:user])
  end
  # layout "explore_time_series"

  # GET /time_series
  # GET /time_series.json
  def index
    @time_series = TimeSeries.meta_only.by_user(current_user.id).sorted

    @css.push("time_series.css")
    @js.push("search.js")

    set_gon_datatables

    respond_to do |format|
      format.html 
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

      # if the language parameter exists and it is valid, use it instead of the default current_locale
      if params[:language].present? && @time_series.languages.include?(params[:language])
        @time_series.current_locale = params[:language]
      end

      @datasets = Dataset.in(id: @time_series.datasets.dataset_ids)

      @license = PageContent.by_name('license')

      @highlights = Highlight.by_time_series(@time_series.id)
      gon.highlight_ids = @highlights.map{|x| x.id}.shuffle if @highlights.present?
      gon.highlight_show_title = false
      gon.highlight_show_links = false
      load_highlight_assets(@highlights.map{|x| x.embed_id}) if @highlights.present?

      @show_title = false

      @css.push("dashboard.css", 'highlights.css', 'list.css', 'boxic.css', 'tabs.css', 'explore.css')
      @js.push("live_search.js", 'highlights.js', 'explore.js')

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
      gon.embed_ids = @time_series.highlights.embed_ids
      gon.private_user = Base64.urlsafe_encode64(current_user.id.to_s)

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

    # if there are category_ids, create mapper objects with them
    params[:time_series][:category_ids].delete('')
      # - remove '' from list
    params[:time_series][:category_ids].each do |category_id|
      @time_series.category_mappers.build(category_id: category_id)
    end

    respond_to do |format|
      if @time_series.save
        format.html { redirect_to time_series_questions_path(@time_series), flash: {success:  t('app.msgs.success_created', :obj => t('mongoid.models.time_series'))} }
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

      # if there are category_ids, see if already exist in mapper - if not add
      # - remove '' from list
      params[:time_series][:category_ids].delete('')
      cat_ids = @time_series.category_mappers.category_ids.map{|x| x.to_s}
      mappers_to_delete = []
      logger.debug "====== existing categories = #{cat_ids}; class = #{cat_ids.first.class}"
      if params[:time_series][:category_ids].present?
        logger.debug "======= cat ids present"
        # if mapper category is not in list, mark for deletion
        @time_series.category_mappers.each do |mapper|
          logger.debug "======= - checking marker cat id #{mapper.category_id} for destroy"

          if !params[:time_series][:category_ids].include?(mapper.category_id.to_s)
            logger.debug "======= -> marking #{mapper.category_id} for destroy"
            mappers_to_delete << mapper.id
          end
        end
        # if cateogry id not in mapper, add id
        params[:time_series][:category_ids].each do |category_id|
          logger.debug "======= - checking form cat id #{category_id} for addition; class = #{category_id.class}"
          if !cat_ids.include?(category_id)
            logger.debug "======= -> adding new category #{category_id}"
            @time_series.category_mappers.build(category_id: category_id) 
          end
        end
      else
        logger.debug "======= cat ids not present"
        # no categories so make sure mapper is nil
        @time_series.category_mappers.each do |mapper|
          mappers_to_delete << mapper.id
        end
      end

      logger.debug "========== -> need to delete #{mappers_to_delete} mapper records"

      # if any mappers are marked as destroy, destroy them
      CategoryMapper.in(id: mappers_to_delete).destroy_all

      respond_to do |format|
        if @time_series.save
          format.html { redirect_to @time_series, flash: {success:  t('app.msgs.success_updated', :obj => t('mongoid.models.time_series'))} }
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
        format.html { redirect_to time_series_index_url, flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.time_series'))} }
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

logger.debug "@@@@@@@@@ there are #{@time_series.questions.length} questions"
@time_series.reload
logger.debug "@@@@@@@@@ there are #{@time_series.questions.length} questions"

      respond_to do |format|
        format.html { redirect_to time_series_questions_path(@time_series), flash: {success:  t('app.msgs.time_series_automatic_match', :count => count) } }
        format.json { head :no_content }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_path(:locale => I18n.locale)
      return
    end
  end



  # add highlight to time series
  def add_highlight
    time_series = TimeSeries.by_id_for_user(params[:id], current_user.id)
    success = false

    if time_series.present?
      success = time_series.highlights.create(embed_id: params[:embed_id], visual_type: params[:visual_type])
    end

    respond_to do |format|
      format.json { render json: success }
    end
  end

  # remove highlight from time series
  def remove_highlight
    time_series = TimeSeries.by_id_for_user(params[:id], current_user.id)
    success = false

    if time_series.present?
      h = time_series.highlights.with_embed_id(params[:embed_id])
      success = h.destroy if h.present?
    end

    respond_to do |format|
      format.html { redirect_to highlights_time_series_path(time_series), flash: {success:  t('app.msgs.highlight_deleted') } }
      format.json { render json: success }
    end
  end

  # indicate highlight should show in home page
  def home_page_highlight
    time_series = TimeSeries.by_id_for_user(params[:id], current_user.id)
    success = false

    if time_series.present?
      h = time_series.highlights.with_embed_id(params[:embed_id])
      if h.present?
        h.show_home_page = true
        success = h.save
      end
    end

    respond_to do |format|
      format.html { redirect_to highlights_time_series_path(time_series), flash: {success:  t('app.msgs.highlight_show_home_page_success') } }
      format.json { render json: success }
    end
  end


  # manage all highlights
  def highlights
    @time_series = TimeSeries.by_id_for_user(params[:id], current_user.id)

    if @time_series.present?
      @highlights = @time_series.highlights

      add_time_series_nav_options

      @js.push('search.js')

      set_gon_datatables

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @time_series }
      end

    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_path(:locale => I18n.locale)
      return
    end

  end

end

class TimeSeriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_owner # set @owner variable
  before_filter :load_time_series, except: [:index, :new, :create] # set @time_series variable using @owner
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, @data_editor_role)
  end

  # GET /time_series
  # GET /time_series.json
  def index
    @time_series = TimeSeries.meta_only.by_owner(@owner.id, current_user.id).sorted

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
    add_time_series_nav_options

    # if the language parameter exists and it is valid, use it instead of the default current_locale
    if params[:language].present? && @time_series.languages.include?(params[:language])
      @time_series.current_locale = params[:language]
    end

    @datasets = Dataset.in(id: @time_series.datasets.dataset_ids)

    @highlights = Highlight.by_time_series(@time_series.id)
    gon.highlight_ids = @highlights.map{|x| x.id}.shuffle if @highlights.present?
    gon.highlight_show_title = false
    gon.highlight_show_links = false
    gon.highlight_admin_link = true
    load_highlight_assets(@highlights.map{|x| x.embed_id}, @dataset.current_locale) if @highlights.present?

    @show_title = false

    @css.push('bootstrap-select.min.css', 'list.css', "dashboard.css", 'highlights.css', 'boxic.css', 'tabs.css', 'explore.css')
    @js.push('bootstrap-select.min.js', "live_search.js", 'highlights.js', 'explore.js')

    respond_to do |format|
      format.html # index.html.erb
    end
  end


  # GET /time_series/1
  # GET /time_series/1.json
  def explore
    add_time_series_nav_options(show_title: false)

    gon.explore_time_series = true
    gon.explore_time_series_ajax_path = explore_time_series_path(:format => :js)
    gon.embed_ids = @time_series.highlights.embed_ids
    gon.private_user = Base64.urlsafe_encode64(current_user.id.to_s)

    # need css for tabbed translations for entering highlight description
    @css.push('tabbed_translation_form.css')

    # this method is in application_controller
    # and gets all of the required information
    # and responds appropriately to html or js
    explore_time_series_generator(@time_series)

  end

  # GET /time_series/new
  # GET /time_series/new.json
  def new
    @time_series = TimeSeries.new
    @datasets = Dataset.by_owner(@owner.id, current_user.id).only_id_title_languages.sorted

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
    @datasets = Dataset.by_owner(@owner.id, current_user.id).only_id_title_languages.sorted

    # add the required assets
    @css.push("time_series.css")
    @js.push("time_series.js", 'cocoon.js')

    add_time_series_nav_options()

    set_tabbed_translation_form_settings
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

    # if there are country_ids, create mapper objects with them
    params[:time_series][:country_ids].delete('')
      # - remove '' from list
    params[:time_series][:country_ids].each do |country_id|
      @time_series.country_mappers.build(country_id: country_id)
    end

    respond_to do |format|
      if @time_series.save
        format.html { redirect_to time_series_questions_path(@owner, @time_series), flash: {success:  t('app.msgs.success_created', :obj => t('mongoid.models.time_series.one'))} }
        format.json { render json: @time_series, status: :created, location: @time_series }
      else
        @datasets = Dataset.by_owner(@owner.id, current_user.id).only_id_title_languages.sorted

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


    # if there are country_ids, see if already exist in mapper - if not add
    # - remove '' from list
    params[:time_series][:country_ids].delete('')
    country_ids = @time_series.country_mappers.country_ids.map{|x| x.to_s}
    mappers_to_delete = []
    logger.debug "====== existing categories = #{country_ids}; class = #{country_ids.first.class}"
    if params[:time_series][:country_ids].present?
      logger.debug "======= country ids present"
      # if mapper country is not in list, mark for deletion
      @time_series.country_mappers.each do |mapper|
        logger.debug "======= - checking marker country id #{mapper.country_id} for destroy"

        if !params[:time_series][:country_ids].include?(mapper.country_id.to_s)
          logger.debug "======= -> marking #{mapper.country_id} for destroy"
          mappers_to_delete << mapper.id
        end
      end
      # if cateogry id not in mapper, add id
      params[:time_series][:country_ids].each do |country_id|
        logger.debug "======= - checking form country id #{country_id} for addition; class = #{country_id.class}"
        if !country_ids.include?(country_id)
          logger.debug "======= -> adding new country #{country_id}"
          @time_series.country_mappers.build(country_id: country_id)
        end
      end
    else
      logger.debug "======= country ids not present"
      # no categories so make sure mapper is nil
      @time_series.country_mappers.each do |mapper|
        mappers_to_delete << mapper.id
      end
    end

    logger.debug "========== -> need to delete #{mappers_to_delete} mapper records"

    # if any mappers are marked as destroy, destroy them
    CountryMapper.in(id: mappers_to_delete).destroy_all


    respond_to do |format|
      if @time_series.save
        format.html { redirect_to @time_series, flash: {success:  t('app.msgs.success_updated', :obj => t('mongoid.models.time_series.one'))} }
        format.json { head :no_content }
      else
        @datasets = Dataset.by_owner(@owner.id, current_user.id).only_id_title_languages.sorted

        # add the required assets
        @js.push("time_series.js", 'cocoon.js')

        add_time_series_nav_options()

        set_tabbed_translation_form_settings

        format.html { render action: "edit" }
        format.json { render json: @time_series.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /time_series/1
  # DELETE /time_series/1.json
  def destroy
    @time_series.destroy

    respond_to do |format|
      format.html { redirect_to time_series_index_url(@owner), flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.time_series.one'))} }
      format.json { head :no_content }
    end
  end



  # automatically assign matching questions
  def automatically_assign_questions
    count = @time_series.automatically_assign_questions

    logger.debug "@@@@@@@@@ there are #{@time_series.questions.length} questions"
    @time_series.reload
    logger.debug "@@@@@@@@@ there are #{@time_series.questions.length} questions"

    respond_to do |format|
      format.html { redirect_to time_series_questions_path(@owner, @time_series), flash: {success:  t('app.msgs.time_series_automatic_match', :count => count) } }
      format.json { head :no_content }
    end
  end

  # mark which answers to not include in the analysis and which can be excluded during anayalsis
  def mass_changes_answers
    respond_to do |format|
      format.html {
        @js.push("mass_changes_answers.js")
        @css.push("mass_changes_answers.css")

        # create data for datatables (faster to load this way)
        gon.datatable_json = []
        @time_series.questions.each_with_index do |question, question_index|
          question.answers.each_with_index do |answer, answer_index|
            gon.datatable_json << {
              code: question.original_code,
              question: question.text,
              answer: answer.text,
              can_exclude: "<input class='can-exclude-input' type='checkbox' #{answer.can_exclude? ? 'checked=\'checked\'' : ''} data-id='#{answer.id}' data-orig='#{answer.can_exclude?}'>",
            }
          end
        end

        add_time_series_nav_options
      }
      format.js {
        @msg = t('app.msgs.mass_change_answer_saved')
        @success = true
        begin
          @time_series.questions.reflag_answers(:can_exclude, params["can-exclude"]) if params["can-exclude"].present? && params["can-exclude"].is_a?(Array)

          # force question callbacks
          @time_series.check_questions_for_changes_status = true

          if !@time_series.save
            @msg = @time_series.errors.full_messages
            @success = false
          end
        rescue Exception => e
          @msg = t('app.msgs.mass_change_answer_not_saved')
          @success = false

          # send the error notification
          ExceptionNotifier::Notifier
            .exception_notification(request.env, e)
            .deliver
        end

      }
    end
  end


  # add highlight to time series
  def add_highlight
    success = @time_series.highlights.create(embed_id: params[:embed_id], visual_type: params[:visual_type], description: params[:description])

    respond_to do |format|
      format.json { render json: success }
    end
  end

  # remove highlight from time series
  def remove_highlight
    h = @time_series.highlights.with_embed_id(params[:embed_id])
    success = h.destroy if h.present?

    respond_to do |format|
      format.html { redirect_to highlights_time_series_path(@owner, @time_series), flash: {success:  t('app.msgs.highlight_deleted') } }
      format.json { render json: success }
    end
  end

  # # indicate highlight should show in home page
  # def home_page_highlight
  #   success = false
  #   h = @time_series.highlights.with_embed_id(params[:embed_id])
  #   if h.present?
  #     h.show_home_page = true
  #     success = h.save
  #   end
  #
  #   respond_to do |format|
  #     format.html { redirect_to highlights_time_series_path(@owner, @time_series), flash: {success:  t('app.msgs.highlight_show_home_page_success') } }
  #     format.json { render json: success }
  #   end
  # end

  # manage all highlights
  def highlights
    @highlights = @time_series.highlights

    add_time_series_nav_options

    @css.push('tabbed_translation_form.css')
    @js.push('search.js', 'highlight_description.js')

    set_gon_datatables

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @time_series }
    end
  end

  # sort all groups/questions
  def sort
    respond_to do |format|
      format.html {
        @items = @time_series.arranged_items(include_questions: true, include_groups: true, include_subgroups: false, include_group_with_no_items: true, group_id: params[:group_id])

        @group = params[:group_id].present? ? @time_series.groups.find(params[:group_id]) : nil

        add_time_series_nav_options
        set_gon_datatables

        # create data for datatables (faster to load this way)
        gon.datatable_json = []
        @items.each_with_index do |item, index|
          id_name, type, name, desc, link, cls = nil
          if item.class == TimeSeriesQuestion
            id_name = 'questions'
            type = I18n.t('mongoid.models.time_series_question.one')
            name = item.code_with_text
          elsif item.class == TimeSeriesGroup
            id_name = 'groups'
            type = I18n.t('mongoid.models.time_series_group.one')
            name = item.title
            desc = item.description.present? ? " - #{item.description}" : ''
            link = view_context.link_to(I18n.t('helpers.links.view_group_items'), params.merge(group_id: item.id), class: 'btn btn-default btn-view-group btn-xs')
            cls = item.parent_id.present? ? 'subgroup' : 'group'
          end

          gon.datatable_json << {
            checkbox: "<input id='time_series_#{id_name}_attributes_#{index}_id' name='time_series[#{id_name}_attributes][#{index}][id]' type='hidden' value='#{item.id}'><input id='time_series_#{id_name}_attributes_#{index}_sort_order name='time_series[#{id_name}_attributes][#{index}][sort_order]' type='hidden' value='#{item.sort_order}'><input class='move-item' name='move-item' type='checkbox' value='#{item.id}'>",
            sort_order: "<input class='form-control sort-order' id='time_series_#{id_name}_attributes_#{index}_sort_order name='time_series[#{id_name}_attributes][#{index}][sort_order]' type='input' value='#{item.sort_order}'>",
            type: type,
            name: "<span class='#{cls}'>#{name}</span>#{desc}",
            link: link
          }
        end

        @css.push('bootstrap-select.min.css', 'sort.css')
        @js.push('bootstrap-select.min.js', "sort.js")

      }
      format.js {
        begin

          @time_series.assign_attributes(params[:time_series])

          @msg = t('app.msgs.sort_saved')
          @success = true
          if !@time_series.save
            @msg = @time_series.errors.full_messages
            @success = false
          end
        rescue Exception => e
          @msg = t('app.msgs.sort_not_saved')
          @success = false

          # send the error notification
          ExceptionNotifier::Notifier
            .exception_notification(request.env, e)
            .deliver
        end

      }
    end
  end

end

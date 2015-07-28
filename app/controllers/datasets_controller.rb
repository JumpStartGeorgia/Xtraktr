class DatasetsController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, @data_editor_role)
  end
  # layout 'explore_data'



  # GET /datasets
  # GET /datasets.json
  def index
    @datasets = Dataset.meta_only.by_user(current_user.id).sorted_title

    @css.push("datasets.css")
    @js.push("search.js")

    set_gon_datatables

    respond_to do |format|
      format.html 
      format.json { render json: @datasets }
    end
  end

  # GET /datasets/1
  # GET /datasets/1.json
  def show
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.blank?
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    else
      add_dataset_nav_options 

      # if the language parameter exists and it is valid, use it instead of the default current_locale
      if params[:language].present? && @dataset.languages.include?(params[:language])
        @dataset.current_locale = params[:language]
      end

      @license = PageContent.by_name('license')

      @highlights = Highlight.by_dataset(@dataset.id)
      gon.highlight_ids = @highlights.map{|x| x.id}.shuffle if @highlights.present?
      gon.highlight_show_title = false
      gon.highlight_show_links = false
      gon.highlight_admin_link = true
      load_highlight_assets(@highlights.map{|x| x.embed_id}) if @highlights.present?

      @show_title = false

      @css.push('bootstrap-select.min.css', 'list.css', "dashboard.css", 'highlights.css', 'boxic.css', 'tabs.css', 'explore.css')
      @js.push('bootstrap-select.min.js', "live_search.js", 'highlights.js', 'explore.js')

      respond_to do |format|
        format.html # index.html.erb
      end
    end

  end

  # GET /datasets/1
  # GET /datasets/1.json
  def explore
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.blank?
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    else
      add_dataset_nav_options(show_title: false)

      gon.explore_data = true
      gon.api_dataset_analysis_path = api_v1_dataset_analysis_path
      gon.embed_ids = @dataset.highlights.embed_ids
      gon.private_user = Base64.urlsafe_encode64(current_user.id.to_s)

      # need css for tabbed translations for entering highlight description
      @css.push('tabbed_translation_form.css')

      # this method is in application_controller
      # and gets all of the required information
      # and responds appropriately to html or js
      explore_data_generator(@dataset, true)
    end

  end



  # GET /datasets/new
  # GET /datasets/new.json
  def new
    @dataset = Dataset.new

    # add the required assets
    @css.push("jquery.ui.datepicker.css", 'datasets.css')
    @js.push('jquery.ui.datepicker.js', "datasets.js", 'cocoon.js')

    add_dataset_nav_options(set_url: false)

    set_tabbed_translation_form_settings
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @dataset }
    end
  end

  # GET /datasets/1/edit
  def edit
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.present?
      # set the date values for the datepicker
      gon.start_gathered_at = @dataset.start_gathered_at.strftime('%m/%d/%Y') if @dataset.start_gathered_at.present?
      gon.end_gathered_at = @dataset.end_gathered_at.strftime('%m/%d/%Y') if @dataset.end_gathered_at.present?
      gon.released_at = @dataset.released_at.strftime('%m/%d/%Y') if @dataset.released_at.present?

      add_dataset_nav_options()

      set_tabbed_translation_form_settings

      # add the required assets
      @css.push("jquery.ui.datepicker.css", "datasets.css")
      @js.push('jquery.ui.datepicker.js', "datasets.js", 'cocoon.js')

    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end

  # POST /datasets
  # POST /datasets.json
  def create
    @dataset = Dataset.new(params[:dataset])

    if !@is_xtraktr
      # just automatically set the source to unicef georgia
      @dataset.source = 'UNICEF Georgia'  
    end

    # if there are category_ids, create mapper objects with them
    params[:dataset][:category_ids].delete('')
      # - remove '' from list
    params[:dataset][:category_ids].each do |category_id|
      @dataset.category_mappers.build(category_id: category_id)
    end

    respond_to do |format|
      if @dataset.save
        format.html { redirect_to dataset_path(@dataset), flash: {success:  t('app.msgs.success_created', :obj => t('mongoid.models.dataset'))} }
        format.json { render json: @dataset, status: :created, location: @dataset }
      else
        # set the date values for the datepicker
        gon.start_gathered_at = @dataset.start_gathered_at.strftime('%m/%d/%Y') if @dataset.start_gathered_at.present?
        gon.end_gathered_at = @dataset.end_gathered_at.strftime('%m/%d/%Y') if @dataset.end_gathered_at.present?
        gon.released_at = @dataset.released_at.strftime('%m/%d/%Y') if @dataset.released_at.present?

        # add the required assets
        @css.push("jquery.ui.datepicker.css", "datasets.css")
        @js.push('jquery.ui.datepicker.js', "datasets.js", 'cocoon.js')

        add_dataset_nav_options({show_title: false, set_url: false})

        set_tabbed_translation_form_settings

        format.html { render action: "new" }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /datasets/1
  # PUT /datasets/1.json
  def update
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.present?

      @dataset.assign_attributes(params[:dataset])

      # if there are category_ids, see if already exist in mapper - if not add
      # - remove '' from list
      params[:dataset][:category_ids].delete('')
      cat_ids = @dataset.category_mappers.category_ids.map{|x| x.to_s}
      mappers_to_delete = []
      logger.debug "====== existing categories = #{cat_ids}; class = #{cat_ids.first.class}"
      if params[:dataset][:category_ids].present?
        logger.debug "======= cat ids present"
        # if mapper category is not in list, mark for deletion
        @dataset.category_mappers.each do |mapper|
          logger.debug "======= - checking marker cat id #{mapper.category_id} for destroy"

          if !params[:dataset][:category_ids].include?(mapper.category_id.to_s)
            logger.debug "======= -> marking #{mapper.category_id} for destroy"
            mappers_to_delete << mapper.id
          end
        end
        # if cateogry id not in mapper, add id
        params[:dataset][:category_ids].each do |category_id|
          logger.debug "======= - checking form cat id #{category_id} for addition; class = #{category_id.class}"
          if !cat_ids.include?(category_id)
            logger.debug "======= -> adding new category #{category_id}"
            @dataset.category_mappers.build(category_id: category_id) 
          end
        end
      else
        logger.debug "======= cat ids not present"
        # no categories so make sure mapper is nil
        @dataset.category_mappers.each do |mapper|
          mappers_to_delete << mapper.id
        end
      end

      logger.debug "========== -> need to delete #{mappers_to_delete} mapper records"

      # if any mappers are marked as destroy, destroy them
      CategoryMapper.in(id: mappers_to_delete).destroy_all

      respond_to do |format|
        if @dataset.save
          format.html { redirect_to dataset_path(@dataset), flash: {success:  t('app.msgs.success_updated', :obj => t('mongoid.models.dataset'))} }
          format.json { head :no_content }
        else
          # set the date values for the datepicker
          gon.start_gathered_at = @dataset.start_gathered_at.strftime('%m/%d/%Y') if @dataset.start_gathered_at.present?
          gon.end_gathered_at = @dataset.end_gathered_at.strftime('%m/%d/%Y') if @dataset.end_gathered_at.present?
          gon.released_at = @dataset.released_at.strftime('%m/%d/%Y') if @dataset.released_at.present?

          # add the required assets
          @css.push("jquery.ui.datepicker.css", "datasets.css")
          @js.push('jquery.ui.datepicker.js', "datasets.js", 'cocoon.js')

          add_dataset_nav_options()

          set_tabbed_translation_form_settings

          logger.debug "@@@@@@@@@@@@@@@ errors = #{@dataset.errors.full_messages}"

          format.html { render action: "edit" }
          format.json { render json: @dataset.errors, status: :unprocessable_entity }
        end
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end

  # DELETE /datasets/1
  # DELETE /datasets/1.json
  def destroy
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)
    if @dataset.present?
      @dataset.destroy

      respond_to do |format|
        format.html { redirect_to datasets_url, flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.dataset'))} }
        format.json { head :no_content }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end


  # show warnings about the data
  def warnings
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.present?
      @no_answers = @dataset.questions.with_no_code_answers
      @bad_answers = @dataset.questions_with_bad_answers
      @no_text = @dataset.questions_with_no_text

      add_dataset_nav_options()

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @dataset }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end


  # mark which questions to not include in the analysis and which to include in download
  def mass_changes_questions
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.present?

      respond_to do |format|
        format.html {
          @js.push("mass_changes_questions.js")
          @css.push("mass_changes_questions.css")

          # create data for datatables (faster to load this way)
          gon.datatable_json = []
          @dataset.questions.with_code_answers.each_with_index do |question, question_index|
            gon.datatable_json << {
              code: question.original_code,
              text: question.text,
              exclude: "<input id='dataset_questions_attributes_#{question_index}_id' name='dataset[questions_attributes][#{question_index}][id]' type='hidden' value='#{question.id}'><input class='exclude-input' name='dataset[questions_attributes][#{question_index}][exclude]' type='checkbox' value='true' #{question.exclude == true ? 'checked=\'checked\'' : ''}>",
              download: "<input class='download-input' name='dataset[questions_attributes][#{question_index}][can_download]' type='checkbox' value='true' #{question.can_download == true ? 'checked=\'checked\'' : ''}>"
            }
          end

          add_dataset_nav_options()

        }
        format.js { 
          begin
            # cannot use simple update_attributes for if value was checked but is not now, 
            # no value exists in params and so no changes take place
            # -> get ids that are true and set them to true
            # -> set rest to false
            exclude_true_ids = params[:dataset][:questions_attributes].select{|k,v| v[:exclude] == 'true'}.map{|k,v| v[:id]}
            exclude_false_ids = params[:dataset][:questions_attributes].select{|k,v| v[:exclude] != 'true'}.map{|k,v| v[:id]}
            @dataset.questions.add_exclude(exclude_true_ids)
            @dataset.questions.remove_exclude(exclude_false_ids)

            download_true_ids = params[:dataset][:questions_attributes].select{|k,v| v[:can_download] == 'true'}.map{|k,v| v[:id]}
            download_false_ids = params[:dataset][:questions_attributes].select{|k,v| v[:can_download] != 'true'}.map{|k,v| v[:id]}
            @dataset.questions.add_can_download(download_true_ids)
            @dataset.questions.remove_can_download(download_false_ids)

            @msg = t('app.msgs.question_exclude_saved')
            @success = true
            if !@dataset.save
              @msg = @dataset.errors.full_messages
              @success = false
            end
          rescue Exception => e 
            @msg = t('app.msgs.question_exclude_not_saved')
            @success = false

            # send the error notification
            ExceptionNotifier::Notifier
              .exception_notification(request.env, e)
              .deliver
          end

        }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end


  # mark which answers to not include in the analysis and which can be excluded during anayalsis
  def mass_changes_answers
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.present?

      respond_to do |format|
        format.html {
          @js.push("mass_changes_answers.js")
          @css.push("mass_changes_answers.css")

          # create data for datatables (faster to load this way)
          gon.datatable_json = []
          @dataset.questions.with_code_answers.each_with_index do |question, question_index|
            question.answers.each_with_index do |answer, answer_index|
              gon.datatable_json << {
                code: question.original_code,
                question: question.text,
                answer: answer.text,
                exclude: "<input id='dataset_questions_attributes_#{question_index}_answers_attributes_#{answer_index}_id' name='dataset[questions_attributes][#{question_index}][answers_attributes][#{answer_index}][id]' type='hidden' value='#{answer.id}'><input class='exclude-input' name='dataset[questions_attributes][#{question_index}][answers_attributes][#{answer_index}][exclude]' type='checkbox' value='true' #{answer.exclude == true ? 'checked=\'checked\'' : ''}>",
                can_exclude: "<input class='can-exclude-input' name='dataset[questions_attributes][#{question_index}][answers_attributes][#{answer_index}][can_exclude]' type='checkbox' value='true' #{answer.can_exclude== true ? 'checked=\'checked\'' : ''}>"
              }
            end
          end



          add_dataset_nav_options()

        }
        format.js { 
          @msg = t('app.msgs.answer_exclude_saved')
          @success = true
          begin
            # cannot use simple update_attributes for if value was checked but is not now, 
            # no value exists in params and so no changes take place
            # -> get ids that are true and set them to true
            # -> set rest to false
            answers = params[:dataset][:questions_attributes].map{|kq,vq| vq[:answers_attributes]}

            exclude_true_ids = answers.map{|x| x.values}.flatten.select{|x| x[:exclude] == 'true'}.map{|x| x[:id]}
            exclude_false_ids = answers.map{|x| x.values}.flatten.select{|x| x[:exclude] != 'true'}.map{|x| x[:id]}
            @dataset.questions.add_answer_exclude(exclude_true_ids)
            @dataset.questions.remove_answer_exclude(exclude_false_ids)

            can_exclude_true_ids = answers.map{|x| x.values}.flatten.select{|x| x[:can_exclude] == 'true'}.map{|x| x[:id]}
            can_exclude_false_ids = answers.map{|x| x.values}.flatten.select{|x| x[:can_exclude] != 'true'}.map{|x| x[:id]}
            @dataset.questions.add_answer_can_exclude(can_exclude_true_ids)
            @dataset.questions.remove_answer_can_exclude(can_exclude_false_ids)

            if !@dataset.save
              @msg = @dataset.errors.full_messages
              @success = false
            end
          rescue Exception => e 
            @msg = t('app.msgs.question_exclude_not_saved')
            @success = false

            # send the error notification
            ExceptionNotifier::Notifier
              .exception_notification(request.env, e)
              .deliver
          end

        }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end

  # # mark which answers users can select to not include in the analysis
  # # during analysis
  # def can_exclude_answers
  #   @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

  #   if @dataset.present?

  #     respond_to do |format|
  #       format.html {
  #         @js.push("exclude_answers.js")
  #         @css.push("exclude_answers.css")

  #         add_dataset_nav_options()

  #       }
  #       format.js { 
  #         @msg = t('app.msgs.answer_can_exclude_saved')
  #         @success = true
  #         begin
  #           # cannot use simple update_attributes for if value was checked but is not now, 
  #           # no value exists in params and so no changes take place
  #           # -> get ids that are true and set them to true
  #           # -> set rest to false
  #           answers = params[:dataset][:questions_attributes].map{|kq,vq| vq[:answers_attributes]}
  #           true_ids = answers.map{|x| x.values}.flatten.select{|x| x[:can_exclude] == 'true'}.map{|x| x[:id]}
  #           false_ids = answers.map{|x| x.values}.flatten.select{|x| x[:can_exclude] != 'true'}.map{|x| x[:id]}

  #           @dataset.questions.add_answer_can_exclude(true_ids)
  #           @dataset.questions.remove_answer_can_exclude(false_ids)

  #           if !@dataset.save
  #             @msg = @dataset.errors.full_messages
  #             @success = false
  #           end
  #         rescue Exception => e 
  #           @msg = t('app.msgs.question_can_exclude_not_saved')
  #           @success = false

  #           # send the error notification
  #           ExceptionNotifier::Notifier
  #             .exception_notification(request.env, e)
  #             .deliver
  #         end

  #       }
  #     end
  #   else
  #     flash[:info] =  t('app.msgs.does_not_exist')
  #     redirect_to datasets_path(:locale => I18n.locale)
  #     return
  #   end
  # end  

  # show which questions are assign to shape sets
  def mappable
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.present?
      @shapeset_count = Shapeset.count

      @mappable = @dataset.questions.mappable

      add_dataset_nav_options()

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @dataset }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end  

  # assign questions to shape sets
  def mappable_form
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.present?

      if request.post? && params['map']['answer'].present? && params['map']['answer'].length == params['map']['shapeset'].length
        mappings = params['map']['answer'].zip(params['map']['shapeset'])

        # assign the shape to the question
        if @dataset.map_question_to_shape(params['question'], params['shapeset'], mappings, params['has_map_adjustable_max_range'])
          flash[:success] =  t('app.msgs.mapping_saved')
          redirect_to mappable_dataset_path(@dataset)
          return
        else
          flash[:warning] =  t('app.msgs.mapping_not_saved')
        end

      end

      @shapesets = Shapeset.sorted
      gon.shapesets = []
      @shapesets.each do |shape|
        gon.shapesets << {id: shape.id, names: shape.names.sort}
      end

      @not_mappable = @dataset.questions.not_mappable
      gon.questions = []
      @not_mappable.each do |question|
        gon.questions << {id: question.id, answers: question.answers.map{|x| {id: x.id, text: x.text}}.sort_by{|x| x[:text]} }
      end

      add_dataset_nav_options()

      @css.push('bootstrap-select.min.css', 'mappable_form.css')
      @js.push('bootstrap-select.min.js', 'mappable_form.js')

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @dataset }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end  

  # edit an existing question mapping
  def mappable_form_edit
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.present? && params[:question_id].present?

      if request.post? && params['map']['answer'].present? && params['map']['answer'].length == params['map']['shapeset'].length
        mappings = params['map']['answer'].zip(params['map']['shapeset'])

        # assign the shape to the question
        if @dataset.map_question_to_shape(params['question_id'], params['shapeset_id'], mappings, params['has_map_adjustable_max_range'])
          flash[:success] =  t('app.msgs.mapping_saved')
          redirect_to mappable_dataset_path(@dataset)
          return
        else
          flash[:warning] =  t('app.msgs.mapping_not_saved')
        end

      end

      @question = @dataset.questions.find_by(id: params[:question_id])

      if @question.present? && @question.is_mappable?
        @shapeset = @question.shapeset

        gon.mappable_form_edit = true

        add_dataset_nav_options()

        @css.push('bootstrap-select.min.css', 'mappable_form.css')
        @js.push('bootstrap-select.min.js', 'mappable_form.js')

        respond_to do |format|
          format.html # index.html.erb
          format.json { render json: @dataset }
        end
      else
        flash[:info] =  t('app.msgs.does_not_exist')
        redirect_to mappable_dataset_path(@dataset)
        return
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end  

  # DELETE /datasets/1
  # DELETE /datasets/1.json
  def remove_mapping
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)
    if @dataset.present?
      if @dataset.remove_question_shape_mapping(params[:question_id])
        flash[:success] =  t('app.msgs.mapping_deleted')
      else
        flash[:warning] =  t('app.msgs.mapping_not_deleted')
      end
      respond_to do |format|
        format.html { redirect_to mappable_dataset_path(@dataset) }
        format.json { head :no_content }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end

  # get the answers for a dataset's question
  def question_answers
    answers = []
    if params[:question_code].present?
      ds = Dataset.find(params[:id])
      if ds.present?
        q = ds.questions.with_code(params[:question_code])
        if q.present?
          answers = q.answers.sorted.to_a
        end
      end

    end

    respond_to do |format|
      format.json { render json: answers.map{|x| x.to_json} }
    end
  end


  # add highlight to dataset
  def add_highlight
    dataset = Dataset.by_id_for_user(params[:id], current_user.id)
    success = false

    if dataset.present?
      success = dataset.highlights.create(embed_id: params[:embed_id], visual_type: params[:visual_type], description: params[:description])
    end

    respond_to do |format|
      format.json { render json: success }
    end
  end

  # remove highlight from dataset
  def remove_highlight
    dataset = Dataset.by_id_for_user(params[:id], current_user.id)
    success = false

    if dataset.present?
      h = dataset.highlights.with_embed_id(params[:embed_id])
      success = h.destroy if h.present?
    end

    respond_to do |format|
      format.html { redirect_to highlights_dataset_path(dataset), flash: {success:  t('app.msgs.highlight_deleted') } }
      format.json { render json: success }
    end
  end

  # remove highlight from dataset
  def update_highlight_description
    dataset = Dataset.by_id_for_user(params[:id], current_user.id)
    success = false

    if dataset.present?
      h = dataset.highlights.with_embed_id(params[:embed_id])
      h.description = params[:description].strip
      success = h.save
    end

    respond_to do |format|
      format.html { redirect_to highlights_dataset_path(dataset), flash: {success:  t('app.msgs.highlight_description_updated') } }
      format.json { render json: success }
    end
  end


  # indicate highlight should show in home page
  def home_page_highlight
    dataset = Dataset.by_id_for_user(params[:id], current_user.id)
    success = false

    if dataset.present?
      h = dataset.highlights.with_embed_id(params[:embed_id])
      if h.present?
        h.show_home_page = true
        success = h.save
      end
    end

    respond_to do |format|
      format.html { redirect_to highlights_dataset_path(dataset), flash: {success:  t('app.msgs.highlight_show_home_page_success') } }
      format.json { render json: success }
    end
  end


  # manage all highlights
  def highlights
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.present?
      @highlights = @dataset.highlights

      add_dataset_nav_options

      @css.push('tabbed_translation_form.css')
      @js.push('search.js', 'highlight_description.js')

      set_gon_datatables

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @dataset }
      end

    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end

  end


  # be able to download complete dataset
  def download_data
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.present?
      add_dataset_nav_options

      respond_to do |format|
        format.html # index.html.erb
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end

  # sort all groups/questions
  def sort
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.present?
      @items = @dataset.arranged_items(include_questions: true, include_groups: true, include_subgroups: false, group_id: params[:group_id])

      @group = params[:group_id].present? ? @dataset.groups.find(params[:group_id]) : nil

      add_dataset_nav_options
      set_gon_datatables

      # create data for datatables (faster to load this way)
      gon.datatable_json = []
      @items.each_with_index do |item, index|
        id_name, type, name, desc, link, cls = nil
        if item.class == Question
          id_name = 'questions'
          type = I18n.t('mongoid.models.question')
          name = item.code_with_text
        elsif item.class == Group
          id_name = 'groups'
          type = I18n.t('mongoid.models.group')
          name = item.title
          desc = item.description.present? ? " - #{item.description}" : ''
          link = view_context.link_to(I18n.t('helpers.links.view_group_items'), params.merge(group_id: item.id), class: 'btn btn-default btn-view-group')
          cls = item.parent_id.present? ? 'subgroup' : 'group'
        end

        gon.datatable_json << {
          checkbox: "<input id='dataset_#{id_name}_attributes_#{index}_id' name='dataset[#{id_name}_attributes][#{index}][id]' type='hidden' value='#{item.id}'><input name='move-item' type='checkbox' value='true'>",
          sort_order: "<input class='form-control sort-order' id='dataset_#{id_name}_attributes_#{index}_sort_order name='dataset[#{id_name}_attributes][#{index}][sort_order]' type='input' value='#{item.sort_order}'>",
          type: type,
          name: "<span class='#{cls}'>#{name}</span>#{desc}",
          link: link
        }
      end

      @css.push('bootstrap-select.min.css', 'sort.css')
      @js.push('bootstrap-select.min.js', "sort.js")

      respond_to do |format|
        format.html # index.html.erb
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end

end



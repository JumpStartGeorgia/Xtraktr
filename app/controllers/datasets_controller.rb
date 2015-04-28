class DatasetsController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, User::ROLES[:user])
  end

  # layout 'explore_data'



  # GET /datasets
  # GET /datasets.json
  def index
    @datasets = Dataset.by_user(current_user.id).sorted

    @css.push("datasets.css")
    @js.push("search.js")

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

      @css.push("dashboard.css")
      @js.push("live_search.js")

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

      # this method is in application_controller
      # and gets all of the required information
      # and responds appropriately to html or js
      explore_data_generator(@dataset)
    end

  end



  # GET /datasets/new
  # GET /datasets/new.json
  def new
    @dataset = Dataset.new

    # add the required assets
    @css.push("jquery.ui.datepicker.css")
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

    respond_to do |format|
      if @dataset.save
        format.html { redirect_to dataset_path(@dataset), notice: t('app.msgs.success_created', :obj => t('mongoid.models.dataset')) }
        format.json { render json: @dataset, status: :created, location: @dataset }
      else
        # set the date values for the datepicker
        gon.start_gathered_at = @dataset.start_gathered_at.strftime('%m/%d/%Y') if @dataset.start_gathered_at.present?
        gon.end_gathered_at = @dataset.end_gathered_at.strftime('%m/%d/%Y') if @dataset.end_gathered_at.present?
        gon.released_at = @dataset.released_at.strftime('%m/%d/%Y') if @dataset.released_at.present?

        # add the required assets
        @css.push("jquery.ui.datepicker.css")
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

      respond_to do |format|
        if @dataset.save
          format.html { redirect_to dataset_path(@dataset), notice: t('app.msgs.success_updated', :obj => t('mongoid.models.dataset')) }
          format.json { head :no_content }
        else
          # set the date values for the datepicker
          gon.start_gathered_at = @dataset.start_gathered_at.strftime('%m/%d/%Y') if @dataset.start_gathered_at.present?
          gon.end_gathered_at = @dataset.end_gathered_at.strftime('%m/%d/%Y') if @dataset.end_gathered_at.present?
          gon.released_at = @dataset.released_at.strftime('%m/%d/%Y') if @dataset.released_at.present?

          # add the required assets
          @css.push("jquery.ui.datepicker.css")
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
        format.html { redirect_to datasets_url }
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


  # mark which questions to not include in the analysis
  def exclude_questions
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.present?

      respond_to do |format|
        format.html {
          @js.push("exclude_questions.js")
          @css.push("exclude_questions.css")

          add_dataset_nav_options()

        }
        format.js { 
          begin
            # cannot use simple update_attributes for if value was checked but is not now, 
            # no value exists in params and so no changes take place
            # -> get ids that are true and set them to true
            # -> set rest to false
            true_ids = params[:dataset][:questions_attributes].select{|k,v| v[:exclude] == 'true'}.map{|k,v| v[:id]}
            false_ids = params[:dataset][:questions_attributes].select{|k,v| v[:exclude] != 'true'}.map{|k,v| v[:id]}

            @dataset.questions.add_exclude(true_ids)
            @dataset.questions.remove_exclude(false_ids)

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


  # mark which answers to not include in the analysis
  def exclude_answers
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.present?

      respond_to do |format|
        format.html {
          @js.push("exclude_answers.js")
          @css.push("exclude_answers.css")

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
            true_ids = answers.map{|x| x.values}.flatten.select{|x| x[:exclude] == 'true'}.map{|x| x[:id]}
            false_ids = answers.map{|x| x.values}.flatten.select{|x| x[:exclude] != 'true'}.map{|x| x[:id]}

            @dataset.questions.add_answer_exclude(true_ids)
            @dataset.questions.remove_answer_exclude(false_ids)

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

  # mark which answers users can select to not include in the analysis
  # during analysis
  def can_exclude_answers
    @dataset = Dataset.by_id_for_user(params[:id], current_user.id)

    if @dataset.present?

      respond_to do |format|
        format.html {
          @js.push("exclude_answers.js")
          @css.push("exclude_answers.css")

          add_dataset_nav_options()

        }
        format.js { 
          @msg = t('app.msgs.answer_can_exclude_saved')
          @success = true
          begin
            # cannot use simple update_attributes for if value was checked but is not now, 
            # no value exists in params and so no changes take place
            # -> get ids that are true and set them to true
            # -> set rest to false
            answers = params[:dataset][:questions_attributes].map{|kq,vq| vq[:answers_attributes]}
            true_ids = answers.map{|x| x.values}.flatten.select{|x| x[:can_exclude] == 'true'}.map{|x| x[:id]}
            false_ids = answers.map{|x| x.values}.flatten.select{|x| x[:can_exclude] != 'true'}.map{|x| x[:id]}

            @dataset.questions.add_answer_can_exclude(true_ids)
            @dataset.questions.remove_answer_can_exclude(false_ids)

            if !@dataset.save
              @msg = @dataset.errors.full_messages
              @success = false
            end
          rescue Exception => e 
            @msg = t('app.msgs.question_can_exclude_not_saved')
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
        if @dataset.map_question_to_shape(params['question'], params['shapeset'], mappings)
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
        if @dataset.map_question_to_shape(params['question_id'], params['shapeset_id'], mappings)
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


end

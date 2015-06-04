class TimeSeriesQuestionsController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, @data_editor_role)
  end

  # layout "explore_time_series"

  # GET /time_series_questions
  # GET /time_series_questions.json
  def index
    @time_series = TimeSeries.by_id_for_user(params[:time_series_id], current_user.id)

    if @time_series.present?
      @questions = @time_series.questions.sorted
      @datasets = @time_series.datasets.sorted
      add_common_options

      respond_to do |format|
        format.html 
        format.js { render json: @questions}
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_index_path(:locale => I18n.locale)
      return
    end

  end

  # GET /time_series_questions/1
  # GET /time_series_questions/1.json
  def show
    @time_series = TimeSeries.by_id_for_user(params[:time_series_id], current_user.id)

    if @time_series.present?
      @time_series_question = @time_series.questions.find(params[:id])
      @datasets = @time_series.datasets.sorted
      add_common_options

      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @time_series_question }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_questions_path(:locale => I18n.locale)
      return
    end
  end

  # GET /time_series_questions/new
  # GET /time_series_questions/new.json
  def new
    @time_series = TimeSeries.by_id_for_user(params[:time_series_id], current_user.id)

    if @time_series.present?
      @time_series_question = @time_series.questions.build
      @datasets = @time_series.datasets.sorted
      # build the dataset questions
      @datasets.each do |dataset|
        @time_series_question.dataset_questions.build(dataset_id: dataset.dataset_id)
      end

      # get the list of questions for each dataset in the time series that are not already in the time series
      @questions = {}
      @datasets.each do |ts_dataset|
        @questions[ts_dataset.dataset_id.to_s] = ts_dataset.dataset.questions.for_analysis_not_in_codes(@time_series.questions.codes_for_dataset(ts_dataset.dataset_id))
      end

      add_common_options

      @is_new = true

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @time_series_question }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_questions_path(:locale => I18n.locale)
      return
    end
  end

  # GET /time_series_questions/1/edit
  def edit
    @time_series = TimeSeries.by_id_for_user(params[:time_series_id], current_user.id)

    if @time_series.present?
      @time_series_question = @time_series.questions.find(params[:id])

      @datasets = @time_series.datasets.sorted

      # get the list of questions for each dataset in the time series that are not already in the time series
      @questions = {}
      @time_series_question.dataset_questions.each do |dataset_question|
        @questions[dataset_question.dataset_id.to_s] = []
        # get all other questions not being used for this dataset
        not_in_use = dataset_question.dataset.questions.for_analysis_not_in_codes(@time_series.questions.codes_for_dataset(dataset_question.dataset_id)).to_a
        if not_in_use.present?
          @questions[dataset_question.dataset_id.to_s] << not_in_use
        end
        # get question for this dataset
        in_use = dataset_question.dataset.questions.with_code(dataset_question.code)
        if in_use.present?
          @questions[dataset_question.dataset_id.to_s] << in_use
        end
        @questions[dataset_question.dataset_id.to_s].flatten!.sort_by!{|x| x.original_code} if @questions[dataset_question.dataset_id.to_s].present?
      end

      add_common_options

    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_questions_path(:locale => I18n.locale)
      return
    end
  end

  # POST /time_series_questions
  # POST /time_series_questions.json
  def create
    @time_series = TimeSeries.by_id_for_user(params[:time_series_id], current_user.id)

    if @time_series.present?
      @time_series_question = @time_series.questions.build(params[:time_series_question])

      respond_to do |format|
        if @time_series_question.save
          format.html { redirect_to time_series_question_path(@time_series, @time_series_question), flash: {success:  t('app.msgs.success_created', :obj => t('mongoid.models.time_series_question'))} }
          format.json { render json: @time_series_question, status: :created, location: @time_series_question }
        else
          @datasets = @time_series.datasets.sorted

          # get the list of questions for each dataset in the time series that are not already in the time series
          @questions = {}
          @datasets.each do |ts_dataset|
            @questions[ts_dataset.dataset_id] = ts_dataset.dataset.questions.for_analysis_not_in_codes(@time_series.questions.codes_for_dataset(ts_dataset.dataset_id))
          end

          add_common_options

          @is_new = true

          format.html { render action: "new" }
          format.json { render json: @time_series_question.errors, status: :unprocessable_entity }
        end
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_questions_path(:locale => I18n.locale)
      return
    end
  end

  # PUT /time_series_questions/1
  # PUT /time_series_questions/1.json
  def update
    @time_series = TimeSeries.by_id_for_user(params[:time_series_id], current_user.id)

    if @time_series.present?
      @time_series_question = @time_series.questions.find(params[:id])

      respond_to do |format|
        if @time_series_question.update_attributes(params[:time_series_question])
          format.html { redirect_to time_series_question_path(@time_series, @time_series_question), flash: {success:  t('app.msgs.success_updated', :obj => t('mongoid.models.time_series_question'))} }
          format.json { head :no_content }
        else
          @datasets = @time_series.datasets.sorted

          # get the list of questions for each dataset in the time series that are not already in the time series
          @questions = {}
          @time_series_question.dataset_questions.each do |dataset_question|
            # get all other questions not being used for this dataset
            @questions[dataset_question.dataset_id] = dataset_question.dataset.questions.for_analysis_not_in_codes(@time_series.questions.codes_for_dataset(dataset_question.dataset_id)).to_a
            # get question for this dataset
            @questions[dataset_question.dataset_id] << dataset_question.dataset.questions.with_code(dataset_question.code)
            @questions[dataset_question.dataset_id].sort_by!{|x| x.original_code}
          end

          add_common_options

          format.html { render action: "edit" }
          format.json { render json: @time_series_question.errors, status: :unprocessable_entity }
        end
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_questions_path(:locale => I18n.locale)
      return
    end
  end

  # DELETE /time_series_questions/1
  # DELETE /time_series_questions/1.json
  def destroy
    @time_series = TimeSeries.by_id_for_user(params[:time_series_id], current_user.id)

    if @time_series.present?
      @time_series_question = @time_series.questions.find(params[:id])
      @time_series_question.destroy

      respond_to do |format|
        format.html { redirect_to time_series_questions_url, flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.time_series_question'))} }
        format.json { head :no_content }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_questions_path(:locale => I18n.locale)
      return
    end
  end



private 
  def add_common_options
    @css.push('tabbed_translation_form.css', 'select2.css', "time_series_questions.css")
    @js.push('cocoon.js', 'select2/select2.min.js', "time_series_questions.js")

    add_time_series_nav_options()

    @languages = Language.sorted

    gon.dataset_question_answers_path = question_answers_dataset_path(id: '[dataset_id]' )
  end

end

class TimeSeriesQuestionsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_owner # set @owner variable
  before_filter {load_time_series(params[:time_series_id])} # set @time_series variable using @owner
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, @data_editor_role)
  end

  # layout "explore_time_series"

  # GET /time_series_questions
  # GET /time_series_questions.json
  def index
    @questions = @time_series.questions.sorted
    @datasets = @time_series.datasets.sorted
    add_common_options

    respond_to do |format|
      format.html
      format.js { render json: @questions}
    end
  end

  # GET /time_series_questions/1
  # GET /time_series_questions/1.json
  def show
    @time_series_question = @time_series.questions.find(params[:id])
    @datasets = @time_series.datasets.sorted
    add_common_options

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @time_series_question }
    end
  end

  # GET /time_series_questions/new
  # GET /time_series_questions/new.json
  def new
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
  end

  # GET /time_series_questions/1/edit
  def edit
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
  end

  # POST /time_series_questions
  # POST /time_series_questions.json
  def create
    @time_series_question = @time_series.questions.build(params[:time_series_question])

    respond_to do |format|
      if @time_series_question.save
        format.html { redirect_to time_series_question_path(@owner, @time_series, @time_series_question), flash: {success:  t('app.msgs.success_created', :obj => t('mongoid.models.time_series_question.one'))} }
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
  end

  # PUT /time_series_questions/1
  # PUT /time_series_questions/1.json
  def update
    @time_series_question = @time_series.questions.find(params[:id])

    respond_to do |format|
      if @time_series_question.update_attributes(params[:time_series_question])
        format.html { redirect_to time_series_question_path(@owner, @time_series, @time_series_question), flash: {success:  t('app.msgs.success_updated', :obj => t('mongoid.models.time_series_question.one'))} }
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
  end

  # DELETE /time_series_questions/1
  # DELETE /time_series_questions/1.json
  def destroy
    @time_series_question = @time_series.questions.find(params[:id])
    @time_series_question.destroy

    respond_to do |format|
      format.html { redirect_to time_series_questions_url(@time_series.owner), flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.time_series_question.one'))} }
      format.json { head :no_content }
    end
  end

  # allow the user to use csv files to update text and settings for questions and answers
  def mass_changes
    add_common_options

    if params[:download].present? && ['questions', 'answers'].include?(params[:download].downcase)
      data = nil
      filename = @time_series.title
      if params[:download].downcase == 'questions'
        if request.format.csv?
          data = @time_series.generate_questions_csv
        elsif request.format.xlsx?
          data = @time_series.generate_questions_xlsx
        end
        filename << "-#{I18n.t('time_series_questions.mass_changes.questions.header')}"
        filename << "-#{I18n.l Time.now, :format => :file}"
      else #answers
        if request.format.csv?
          data = @time_series.generate_answers_csv
        elsif request.format.xlsx?
          data = @time_series.generate_answers_xlsx
        end
        
        filename << "-#{I18n.t('time_series_questions.mass_changes.answers.header')}"
        filename << "-#{I18n.l Time.now, :format => :file}"
      end
 
      respond_to do |format|
        format.xlsx { send_data data, :filename=> "#{clean_filename(filename)}.xlsx" }
        format.csv { send_data data, :filename=> "#{clean_filename(filename)}.csv" }
      end
    else
      respond_to do |format|
        format.html
      end
    end
  end

  def load_mass_changes_questions
    file = params[:file]
    if file.present?
      content_type = file.content_type
      if content_type.present? && ["text/csv", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"].include?(content_type)
        msg, counts = @time_series.process_questions_by_type(file, (content_type == "text/csv" ? :csv : :xlsx))

        # if no msg than there were no errors
        if msg.blank?
          #logger.debug "****************** total changes: #{counts.map{|k,v| k + ' - ' + v.to_s}.join(', ')}"
          flash[:success] =  t('app.msgs.mass_upload_questions_success', count: view_context.number_with_delimiter(counts['overall']))
        else
          #logger.debug "****************** error = #{msg}"
          flash[:error] =  t('app.msgs.mass_upload_questions_error', msg: msg)
        end
      end
    end

    redirect_to mass_changes_time_series_questions_path
    return
  end

  def load_mass_changes_answers
    file = params[:file]
    if file.present?
      content_type = file.content_type
      if content_type.present? && ["text/csv", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"].include?(content_type)
        msg, counts = @time_series.process_answers_by_type(file, (content_type == "text/csv" ? :csv : :xlsx))

        # if no msg than there were no errors
        if msg.blank?
          #logger.debug "****************** total changes: #{counts.map{|k,v| k + ' - ' + v.to_s}.join(', ')}"
          flash[:success] =  t('app.msgs.mass_upload_answers_success', count: view_context.number_with_delimiter(counts['overall']))
        else
          flash[:error] =  t('app.msgs.mass_upload_answers_error', msg: msg)
        end
      end
    end

    redirect_to mass_changes_time_series_questions_path
    return
  end

private
  def add_common_options
    @css.push('tabbed_translation_form.css', "time_series_questions.css")
    @js.push('cocoon.js', "time_series_questions.js")

    add_time_series_nav_options()

    @languages = Language.sorted

    gon.dataset_question_answers_path = question_answers_dataset_path(owner_id: @owner.slug, id: '[dataset_id]' )
  end

end

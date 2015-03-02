class TimeSeriesQuestionsController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, User::ROLES[:user])
  end

  layout "explore_time_series"

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
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end

  end

  # GET /time_series_questions/1
  # GET /time_series_questions/1.json
  def show
    @time_series_question = TimeSeriesQuestion.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @time_series_question }
    end
  end

  # GET /time_series_questions/new
  # GET /time_series_questions/new.json
  def new
    @time_series_question = TimeSeriesQuestion.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @time_series_question }
    end
  end

  # GET /time_series_questions/1/edit
  def edit
    @time_series_question = TimeSeriesQuestion.find(params[:id])
  end

  # POST /time_series_questions
  # POST /time_series_questions.json
  def create
    @time_series_question = TimeSeriesQuestion.new(params[:time_series_question])

    respond_to do |format|
      if @time_series_question.save
        format.html { redirect_to @time_series_question, notice: 'Time series question was successfully created.' }
        format.json { render json: @time_series_question, status: :created, location: @time_series_question }
      else
        format.html { render action: "new" }
        format.json { render json: @time_series_question.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /time_series_questions/1
  # PUT /time_series_questions/1.json
  def update
    @time_series_question = TimeSeriesQuestion.find(params[:id])

    respond_to do |format|
      if @time_series_question.update_attributes(params[:time_series_question])
        format.html { redirect_to @time_series_question, notice: 'Time series question was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @time_series_question.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /time_series_questions/1
  # DELETE /time_series_questions/1.json
  def destroy
    @time_series_question = TimeSeriesQuestion.find(params[:id])
    @time_series_question.destroy

    respond_to do |format|
      format.html { redirect_to time_series_questions_url }
      format.json { head :no_content }
    end
  end

private 
  def add_common_options
    @css.push('tabbed_translation_form.css', "time_series_questions.css")
    @js.push('cocoon.js', "time_series_questions.js")

    add_time_series_nav_options()

    @languages = Language.sorted
  end

end

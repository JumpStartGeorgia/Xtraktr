class QuestionsController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, @data_editor_role)
  end
  # layout "explore_data"


  # GET /questions
  # GET /questions.json
  def index
    @dataset = Dataset.by_id_for_user(params[:dataset_id], current_user.id)

    if @dataset.present?
      @questions = @dataset.questions

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

  # GET /questions/1
  # GET /questions/1.json
  def show
    @dataset = Dataset.by_id_for_user(params[:dataset_id], current_user.id)

    if @dataset.present?
      @question = @dataset.questions.find(params[:id])

      add_common_options
      #set_tabbed_translation_form_settings

      respond_to do |format|
        format.html 
        format.js { render json: @question}
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to dataset_questions_path(:locale => I18n.locale)
      return
    end
  end

  # # GET /questions/new
  # # GET /questions/new.json
  # def new
  #   @question = Question.new

  #   respond_to do |format|
  #     format.html # new.html.erb
  #     format.json { render json: @question }
  #   end
  # end

  # GET /questions/1/edit
  def edit
    @dataset = Dataset.by_id_for_user(params[:dataset_id], current_user.id)

    if @dataset.present?
      @question = @dataset.questions.find(params[:id])

      add_common_options
      #set_tabbed_translation_form_settings
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to dataset_questions_path(:locale => I18n.locale)
      return
    end
  end

  # # POST /questions
  # # POST /questions.json
  # def create
  #   @question = Question.new(params[:question])

  #   respond_to do |format|
  #     if @question.save
  #       format.html { redirect_to @question, notice: t('app.msgs.success_created', :obj => t('mongoid.models.question')) }
  #       format.json { render json: @question, status: :created, location: @question }
  #     else
  #       format.html { render action: "new" }
  #       format.json { render json: @question.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # PUT /questions/1
  # PUT /questions/1.json
  def update
    @dataset = Dataset.by_id_for_user(params[:dataset_id], current_user.id)

    if @dataset.present?
      @question = @dataset.questions.find(params[:id])

      if @question.present?
        respond_to do |format|
          if @question.update_attributes(params[:question])
            format.html { redirect_to dataset_question_path(@dataset, @question), notice: t('app.msgs.success_updated', :obj => t('mongoid.models.question')) }
            format.json { head :no_content }
          else
            add_common_options
            #set_tabbed_translation_form_settings

            format.html { render action: "edit" }
            format.json { render json: @question.errors, status: :unprocessable_entity }
          end
        end
      else
        flash[:info] =  t('app.msgs.does_not_exist')
        redirect_to dataset_questions_path(:locale => I18n.locale)
        return
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end

  # # DELETE /questions/1
  # # DELETE /questions/1.json
  # def destroy
  #   @question = Question.find(params[:id])
  #   @question.destroy

  #   respond_to do |format|
  #     format.html { redirect_to questions_url }
  #     format.json { head :no_content }
  #   end
  # end


  # allow the user to use csv files to update text and settings for questions and answers
  def mass_changes
    @dataset = Dataset.by_id_for_user(params[:dataset_id], current_user.id)

    if @dataset.present?

      add_common_options

      if params[:download].present? && ['questions', 'answers'].include?(params[:download].downcase)
        csv = nil
        filename = @dataset.title
        if params[:download].downcase == 'questions'
          csv = @dataset.generate_questions_csv
          filename << "-#{I18n.t('questions.mass_changes.questions.header')}"
          filename << "-#{I18n.l Time.now, :format => :file}"
        else #answers
          csv = @dataset.generate_answers_csv
          filename << "-#{I18n.t('questions.mass_changes.answers.header')}"
          filename << "-#{I18n.l Time.now, :format => :file}"
        end
        respond_to do |format|
          format.csv {
            send_data csv, 
              :type => 'text/csv; header=present',
              :disposition => "attachment; filename=#{clean_filename(filename)}.csv"
          }
        end
      else
        respond_to do |format|
          format.html 
        end
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end

  def load_mass_changes_questions
    @dataset = Dataset.by_id_for_user(params[:dataset_id], current_user.id)

    if @dataset.present?
      if params[:file].present?
        msg, counts = @dataset.process_questions_csv(params[:file])

        # if no msg than there were no errors
        if msg.blank?
          logger.debug "****************** total changes: #{counts.map{|k,v| k + ' - ' + v.to_s}.join(', ')}"
          flash[:success] =  t('app.msgs.mass_upload_questions_success', count: counts['overall'])
        else
          flash[:error] =  t('app.msgs.mass_upload_questions_error', msg: msg)
        end
      end

      redirect_to mass_changes_dataset_questions_path
      return
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end


  def load_mass_changes_answers
    @dataset = Dataset.by_id_for_user(params[:dataset_id], current_user.id)

    if @dataset.present?
      if params[:file].present?
        msg, counts = @dataset.process_answers_csv(params[:file])

        # if no msg than there were no errors
        if msg.blank?
          logger.debug "****************** total changes: #{counts.map{|k,v| k + ' - ' + v.to_s}.join(', ')}"
          flash[:success] =  t('app.msgs.mass_upload_answers_success', count: counts['overall'])
        else
          flash[:error] =  t('app.msgs.mass_upload_answers_error', msg: msg)
        end
      end

      redirect_to mass_changes_dataset_questions_path
      return
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end

private 
  def add_common_options
    @css.push('tabbed_translation_form.css', "questions.css")
    @js.push('cocoon.js', "questions.js")

    add_dataset_nav_options()

    @languages = Language.sorted
  end
end

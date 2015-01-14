class QuestionsController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, User::ROLES[:user])
  end

  layout "explore_data"


  # GET /questions
  # GET /questions.json
  def index
    @dataset = Dataset.where(user_id: current_user.id, id: params[:dataset_id]).first

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
    @dataset = Dataset.where(user_id: current_user.id, id: params[:dataset_id]).first

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
    @dataset = Dataset.where(user_id: current_user.id, id: params[:dataset_id]).first

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
    @dataset = Dataset.where(user_id: current_user.id, id: params[:dataset_id]).first

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


private 
  def add_common_options
    @css.push('tabbed_translation_form.css', "questions.css")
    @js.push('cocoon.js', "questions.js")

    add_dataset_nav_options()

    @languages = Language.sorted
  end
end

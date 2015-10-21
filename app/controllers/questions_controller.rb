class QuestionsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_owner # set @owner variable
  before_filter {load_dataset(params[:dataset_id])} # set @dataset variable using @owner
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, @data_editor_role)
  end
  # layout "explore_data"


  # GET /questions
  # GET /questions.json
  def index
    @questions = @dataset.questions

    # create data for datatables (faster to load this way)
    gon.datatable_json = []
    @questions.each do |question|
      gon.datatable_json << {
        view: view_context.link_to(I18n.t('helpers.links.view'), dataset_question_path(@owner, @dataset, question), class: 'btn btn-default'),
        code: question.original_code,
        text: question.text,
        is_weight: view_context.format_boolean_flag(question.is_weight),
        has_answers: view_context.format_boolean_flag(question.has_code_answers),
        exclude: view_context.format_boolean_flag(question.exclude),
        download: view_context.format_boolean_flag(question.can_download),
        mappable: view_context.format_boolean_flag(question.is_mappable),
        action: view_context.link_to('', edit_dataset_question_path(@owner, @dataset, question), :title => t('helpers.links.edit'), :class => 'btn btn-edit btn-xs')
      }
    end

    add_common_options

    respond_to do |format|
      format.html
      format.js { render json: @questions}
    end
  end

  # GET /questions/1
  # GET /questions/1.json
  def show
    @question = @dataset.questions.find(params[:id])

    add_common_options
    #set_tabbed_translation_form_settings

    respond_to do |format|
      format.html
      format.js { render json: @question}
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
    @question = @dataset.questions.find(params[:id])

    add_common_options
    #set_tabbed_translation_form_settings
  end

  # # POST /questions
  # # POST /questions.json
  # def create
  #   @question = Question.new(params[:question])

  #   respond_to do |format|
  #     if @question.save
  #       format.html { redirect_to @question, flash: {success:  t('app.msgs.success_created', :obj => t('mongoid.models.question'))} }
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
    @question = @dataset.questions.find(params[:id])

    if @question.present?
      respond_to do |format|
        if @question.update_attributes(params[:question])
          format.html { redirect_to dataset_question_path(@owner, @dataset, @question), flash: {success:  t('app.msgs.success_updated', :obj => t('mongoid.models.question'))} }
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
      redirect_to dataset_questions_path(:locale => I18n.locale, :owner => @owner.slug)
      return
    end
  end

  # # DELETE /questions/1
  # # DELETE /questions/1.json
  # def destroy
  #   @question = Question.find(params[:id])
  #   @question.destroy

  #   respond_to do |format|
  #     format.html { redirect_to questions_url, flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.question'))} }
  #     format.json { head :no_content }
  #   end
  # end


  # allow the user to use csv files to update text and settings for questions and answers
  def mass_changes
    add_common_options

    if params[:download].present? && ['questions', 'answers'].include?(params[:download].downcase)
      data = nil
      filename = @dataset.title
      if params[:download].downcase == 'questions'
        if request.format.csv?
          data = @dataset.generate_questions_csv
        elsif request.format.xlsx?
          data = @dataset.generate_questions_xlsx
        end
        filename << "-#{I18n.t('questions.mass_changes.questions.header')}"
        filename << "-#{I18n.l Time.now, :format => :file}"
      else #answers
        if request.format.csv?
          data = @dataset.generate_answers_csv
        elsif request.format.xlsx?
          data = @dataset.generate_answers_xlsx
        end
        
        filename << "-#{I18n.t('questions.mass_changes.answers.header')}"
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
        msg, counts = @dataset.process_questions_by_type(file, (content_type == "text/csv" ? :csv : :xlsx))
         Rails.logger.debug("--------------------------------------------here8")

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

    redirect_to mass_changes_dataset_questions_path
    return
  end
# "- download works great
# - upload has problem in that the Georgian language is lost even though it is in the spreadsheet.
# Check code and if all looks good, check the clean_string method in the custom_translations method. This might be stripping out the Georgian text. See if when parsing the file if it is possible to add encoding attribute and set it to utf8. If nothing else seems to fix it, create a new clean_string method (clean_string_for_spreadsheets) and only use it in the upload methods. In this method, for now, do nothing. Just return the string that was passed in. If that works, go with it for now. Dealing with dataset and spreadsheet files is a pain when it comes to encoding and I am still trying to get it working nicely.

# Small changes:
# - make Download Question/Answer Template line left aligned
# - add the following text as a new paragraph to the template explanation text:
#  ???????? If you are using Excel, please use the XLSX format for Excel cannot read non-latin characters in CSV files.

# Time series:
# - time series questions only have code answers, so just get all answers"

  def load_mass_changes_answers
    file = params[:file]
    if file.present?
      content_type = file.content_type
      if content_type.present? && ["text/csv", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"].include?(content_type)
        msg, counts = @dataset.process_answers_by_type(file, (content_type == "text/csv" ? :csv : :xlsx))

        # if no msg than there were no errors
        if msg.blank?
          #logger.debug "****************** total changes: #{counts.map{|k,v| k + ' - ' + v.to_s}.join(', ')}"
          flash[:success] =  t('app.msgs.mass_upload_answers_success', count: view_context.number_with_delimiter(counts['overall']))
        else
          flash[:error] =  t('app.msgs.mass_upload_answers_error', msg: msg)
        end
      end
    end

    redirect_to mass_changes_dataset_questions_path
    return
  end

private
  def add_common_options
    @css.push('tabbed_translation_form.css', "questions.css")
    @js.push('cocoon.js', "questions.js")

    add_dataset_nav_options()

    @languages = Language.sorted
  end
end

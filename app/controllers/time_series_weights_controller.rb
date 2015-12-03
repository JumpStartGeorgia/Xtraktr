class TimeSeriesWeightsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_owner # set @owner variable
  before_filter {load_time_series(params[:time_series_id])} # set @time_series variable using @owner
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, @data_editor_role)
  end

  # GET /weights
  # GET /weights.json
  def index
    @weights = @time_series.weights

    add_common_options(false)

    respond_to do |format|
      format.html
      format.js { render json: @weights}
    end
  end

  # # GET /weights/1
  # # GET /weights/1.json
  # def show
  #   @weight = Weight.find(params[:id])

  #   respond_to do |format|
  #     format.html # show.html.erb
  #     format.json { render json: @weight }
  #   end
  # end

  # GET /weights/new
  # GET /weights/new.json
  def new
    @weight = @time_series.weights.new(is_default: true, applies_to_all: true)

    add_common_options

    @weight.dataset_id = @datasets.last.dataset_id

    # build the dataset questions
    @datasets.each do |dataset|
      @weight.assignments.build(dataset_id: dataset.dataset_id)
    end

    @is_new = true

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @weight }
    end
  end

  # GET /weights/1/edit
  def edit
    @weight = @time_series.weights.find(params[:id])

    add_common_options
    #set_tabbed_translation_form_settings

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @weight }
    end
  end

  # POST /weights
  # POST /weights.json
  def create
    @weight = @time_series.weights.new(params[:time_series_weight])

    respond_to do |format|
      if @weight.save
        format.html { redirect_to time_series_weights_path(@owner), flash: {success:  t('app.msgs.success_created', :obj => t('mongoid.models.time_series_weight.one'))} }
        format.json { render json: @weight, status: :created, location: @weight }
      else
        add_common_options
        @is_new = true

        format.html { render action: "new" }
        format.json { render json: @weight.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /weights/1
  # PUT /weights/1.json
  def update
    @weight = @time_series.weights.find(params[:id])

    if @weight.present?
      respond_to do |format|
        if @weight.update_attributes(params[:time_series_weight])
          format.html { redirect_to time_series_weights_path(@owner), flash: {success:  t('app.msgs.success_updated', :obj => t('mongoid.models.time_series_weight.one'))} }
          format.json { head :no_content }
        else
          add_common_options

          format.html { render action: "edit" }
          format.json { render json: @weight.errors, status: :unprocessable_entity }
        end
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to time_series_weights_path(:locale => I18n.locale, :owner_id => @owner.slug)
      return
    end
  end

  # DELETE /weights/1
  # DELETE /weights/1.json
  def destroy
    @weight = @time_series.weights.find(params[:id])
    @weight.destroy

    respond_to do |format|
      format.html { redirect_to time_series_weights_url(@owner), flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.time_series_weight.one'))} }
      format.json { head :no_content }
    end
  end

private
  def add_common_options(for_form=true)
    @css.push("weights.css")
    @js.push("time_series_weights.js")

    if for_form
      @css.push('bootstrap-select.min.css', 'tabbed_translation_form.css')
      @js.push('bootstrap-select.min.js')

      @languages = Language.sorted

      @datasets = @time_series.datasets.sorted

      # get the list of questions for each dataset that do not have answers
      @questions = {}
      @datasets.each do |dataset|
        # get the dataset question
        # - if it does not exist, build it
        dataset_assignment = @weight.assignments.with_dataset(dataset.dataset_id)
        dataset_assignment = @weight.assignments.build(dataset_id: dataset.dataset_id) if dataset_assignment.nil?

        @questions[dataset_assignment.dataset_id.to_s] = dataset.dataset.questions.available_to_have_unique_ids
      end

      gon.datatable_json = create_datatable_json(@time_series.questions, @weight.codes, @weight.id)

    end

    add_time_series_nav_options

  end

  # create json data to load datatable for it is faster
  # format: {checkbox: input html, code: quesiton.code, text: question.text}
  def create_datatable_json(questions, weight_codes, weight_id)
    json = []
    weight_codes ||= []

    questions.each do |question|
      json << {
        checkbox: "<input name='time_series_weight[codes][]' type='checkbox' value='#{question.code}' #{weight_codes.include?(question.code) ? 'checked=\'checked\'' : ''}>",
        code: question.code,
        text: question.text,
        other_weights: question.weight_titles(weight_id).join(', ')
      }
    end


    return json
  end

end

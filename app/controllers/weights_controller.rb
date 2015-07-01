class WeightsController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, @data_editor_role)
  end

  # GET /weights
  # GET /weights.json
  def index
    @dataset = Dataset.by_id_for_user(params[:dataset_id], current_user.id)

    if @dataset.present?
      @weights = @dataset.weights

      add_common_options(false)

      respond_to do |format|
        format.html 
        format.js { render json: @weights}
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
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
    @dataset = Dataset.by_id_for_user(params[:dataset_id], current_user.id)

    if @dataset.present?
      @weight = Weight.new(is_default: true, applies_to_all: true)
      gon.datatable_json = create_datatable_json(@dataset.questions, @weight.codes, @weight.id)

      add_common_options
      #set_tabbed_translation_form_settings

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @weight }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to dataset_weights_path(:locale => I18n.locale)
      return
    end
  end

  # GET /weights/1/edit
  def edit
    @dataset = Dataset.by_id_for_user(params[:dataset_id], current_user.id)

    if @dataset.present?
      @weight = @dataset.weights.find(params[:id])
      gon.datatable_json = create_datatable_json(@dataset.questions, @weight.codes, @weight.id)

      add_common_options
      #set_tabbed_translation_form_settings

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @weight }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to dataset_weights_path(:locale => I18n.locale)
      return
    end
  end

  # POST /weights
  # POST /weights.json
  def create
    @dataset = Dataset.by_id_for_user(params[:dataset_id], current_user.id)

    if @dataset.present?
      @weight = @dataset.weights.new(params[:weight])

      respond_to do |format|
        if @weight.save
          format.html { redirect_to dataset_weights_path, flash: {success:  t('app.msgs.success_created', :obj => t('mongoid.models.weight'))} }
          format.json { render json: @weight, status: :created, location: @weight }
        else
          gon.datatable_json = create_datatable_json(@dataset.questions, @weight.codes, @weight.id)

          add_common_options

          format.html { render action: "new" }
          format.json { render json: @weight.errors, status: :unprocessable_entity }
        end
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end

  # PUT /weights/1
  # PUT /weights/1.json
  def update
    @dataset = Dataset.by_id_for_user(params[:dataset_id], current_user.id)

    if @dataset.present?
      @weight = @dataset.weights.find(params[:id])

      if @weight.present?
        respond_to do |format|
          if @weight.update_attributes(params[:weight])
            format.html { redirect_to dataset_weights_path, flash: {success:  t('app.msgs.success_updated', :obj => t('mongoid.models.weight'))} }
            format.json { head :no_content }
          else
            gon.datatable_json = create_datatable_json(@dataset.questions, @weight.codes, @weight.id)

            add_common_options

            format.html { render action: "edit" }
            format.json { render json: @weight.errors, status: :unprocessable_entity }
          end
        end
      else
        flash[:info] =  t('app.msgs.does_not_exist')
        redirect_to dataset_weights_path(:locale => I18n.locale)
        return
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end

  # DELETE /weights/1
  # DELETE /weights/1.json
  def destroy
    @dataset = Dataset.by_id_for_user(params[:dataset_id], current_user.id)

    if @dataset.present?
      @weight = @dataset.weights.find(params[:id])
      @weight.destroy

      respond_to do |format|
        format.html { redirect_to dataset_weights_url, flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.weight'))} }
        format.json { head :no_content }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to datasets_path(:locale => I18n.locale)
      return
    end
  end

private 
  def add_common_options(for_form=true)
    @css.push("weights.css")
    @js.push("weights.js")

    if for_form
      @css.push('bootstrap-select.min.css', 'tabbed_translation_form.css')
      @js.push('bootstrap-select.min.js')
      
      @languages = Language.sorted
    end

    add_dataset_nav_options

  end

  # create json data to load datatable for it is faster
  # format: {checkbox: input html, code: quesiton.code, text: question.text}
  def create_datatable_json(questions, weight_codes, weight_id)
    json = []
    weight_codes ||= []

    questions.each do |question|
      json << {
        checkbox: "<input name='weight[codes][]' type='checkbox' value='#{question.code}' #{weight_codes.include?(question.code) ? 'checked=\'checked\'' : ''}>", 
        code: question.code, 
        text: question.text,
        other_weights: question.weight_titles(weight_id).join(', ')
      }
    end


    return json
  end

end

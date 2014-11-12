class Admin::DatasetsController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, User::ROLES[:user])
  end

  # GET /datasets
  # GET /datasets.json
  def index
    @datasets = Dataset.where(user_id: current_user.id).sorted

    @css.push("datasets.css")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @datasets }
    end
  end

  # GET /datasets/1
  # GET /datasets/1.json
  def show
    @dataset = Dataset.where(user_id: current_user.id, id: params[:id]).first

    @css.push("datasets.css")

    if @dataset.present?
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @dataset }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to admin_datasets_path(:locale => I18n.locale)
      return
    end
  end

  # GET /datasets/new
  # GET /datasets/new.json
  def new
    @dataset = Dataset.new

    # add the required assets
    @css.push("jquery.ui.datepicker.css")
    @js.push('jquery.ui.datepicker.js', "datasets.js")

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @dataset }
    end
  end

  # GET /datasets/1/edit
  def edit
    @dataset = Dataset.where(user_id: current_user.id, id: params[:id]).first

    if @dataset.present?
      # set the date values for the datepicker
      gon.start_gathered_at = @dataset.start_gathered_at.strftime('%m/%d/%Y') if @dataset.start_gathered_at.present?
      gon.end_gathered_at = @dataset.end_gathered_at.strftime('%m/%d/%Y') if @dataset.end_gathered_at.present?
      gon.released_at = @dataset.released_at.strftime('%m/%d/%Y') if @dataset.released_at.present?

      # add the required assets
      @css.push("jquery.ui.datepicker.css")
      @js.push('jquery.ui.datepicker.js', "datasets.js")
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to admin_datasets_path(:locale => I18n.locale)
      return
    end
  end

  # POST /datasets
  # POST /datasets.json
  def create
    @dataset = Dataset.new(params[:dataset])

    respond_to do |format|
      if @dataset.save
        format.html { redirect_to admin_dataset_path(@dataset), notice: t('app.msgs.success_created', :obj => t('mongoid.models.dataset')) }
        format.json { render json: @dataset, status: :created, location: @dataset }
      else
        # set the date values for the datepicker
        gon.start_gathered_at = @dataset.start_gathered_at.strftime('%m/%d/%Y') if @dataset.start_gathered_at.present?
        gon.end_gathered_at = @dataset.end_gathered_at.strftime('%m/%d/%Y') if @dataset.end_gathered_at.present?
        gon.released_at = @dataset.released_at.strftime('%m/%d/%Y') if @dataset.released_at.present?

        # add the required assets
        @css.push("jquery.ui.datepicker.css")
        @js.push('jquery.ui.datepicker.js', "datasets.js")

        format.html { render action: "new" }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /datasets/1
  # PUT /datasets/1.json
  def update
    @dataset = Dataset.where(user_id: current_user.id, id: params[:id]).first

    if @dataset.present?
      @dataset.assign_attributes(params[:dataset])

      respond_to do |format|
        if @dataset.save
          format.html { redirect_to admin_dataset_path(@dataset), notice: t('app.msgs.success_updated', :obj => t('mongoid.models.dataset')) }
          format.json { head :no_content }
        else
          # set the date values for the datepicker
          gon.start_gathered_at = @dataset.start_gathered_at.strftime('%m/%d/%Y') if @dataset.start_gathered_at.present?
          gon.end_gathered_at = @dataset.end_gathered_at.strftime('%m/%d/%Y') if @dataset.end_gathered_at.present?
          gon.released_at = @dataset.released_at.strftime('%m/%d/%Y') if @dataset.released_at.present?

          # add the required assets
          @css.push("jquery.ui.datepicker.css")
          @js.push('jquery.ui.datepicker.js', "datasets.js")

          format.html { render action: "edit" }
          format.json { render json: @dataset.errors, status: :unprocessable_entity }
        end
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to admin_datasets_path(:locale => I18n.locale)
      return
    end
  end

  # DELETE /datasets/1
  # DELETE /datasets/1.json
  def destroy
    @dataset = Dataset.where(user_id: current_user.id, id: params[:id]).first
    if @dataset.present?
      @dataset.destroy

      respond_to do |format|
        format.html { redirect_to admin_datasets_url }
        format.json { head :no_content }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to admin_datasets_path(:locale => I18n.locale)
      return
    end
  end


  # show warnings about the data
  def warnings
    @dataset = Dataset.where(user_id: current_user.id, id: params[:id]).warnings.first

    if @dataset.present?
      @no_answers = @dataset.questions.with_no_code_answers
      @bad_answers = @dataset.questions_with_bad_answers
      @no_text = @dataset.questions_with_no_text

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @dataset }
      end
    else
      flash[:info] =  t('app.msgs.does_not_exist')
      redirect_to admin_datasets_path(:locale => I18n.locale)
      return
    end
  end
end

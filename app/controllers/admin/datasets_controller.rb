class Admin::DatasetsController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, User::ROLES[:user])
  end

  # GET /datasets
  # GET /datasets.json
  def index
    @datasets = Dataset.where(user_id: current_user.id).basic_info

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @datasets }
    end
  end

  # GET /datasets/1
  # GET /datasets/1.json
  def show
    @dataset = Dataset.basic_info.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @dataset }
    end
  end

  # GET /datasets/new
  # GET /datasets/new.json
  def new
    @dataset = Dataset.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @dataset }
    end
  end

  # GET /datasets/1/edit
  def edit
    @dataset = Dataset.find(params[:id])
  end

  # POST /datasets
  # POST /datasets.json
  def create
    @dataset = Dataset.new(params[:dataset])

    respond_to do |format|
      if @dataset.save
        format.html { redirect_to admin_dataset_path(@dataset), notice: t('app.msgs.success_created', :obj => t('activerecord.models.dataset')) }
        format.json { render json: @dataset, status: :created, location: @dataset }
      else
        format.html { render action: "new" }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /datasets/1
  # PUT /datasets/1.json
  def update
    @dataset = Dataset.find(params[:id])

    @dataset.assign_attributes(params[:dataset])

    respond_to do |format|
      if @dataset.save
        format.html { redirect_to admin_dataset_path(@dataset), notice: t('app.msgs.success_updated', :obj => t('activerecord.models.dataset')) }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @dataset.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /datasets/1
  # DELETE /datasets/1.json
  def destroy
    @dataset = Dataset.find(params[:id])
    @dataset.destroy

    respond_to do |format|
      format.html { redirect_to admin_datasets_url }
      format.json { head :no_content }
    end
  end


  # show warnings about the data
  def warnings
    @dataset = Dataset.warnings.find(params[:id])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @dataset }
    end
  end
end

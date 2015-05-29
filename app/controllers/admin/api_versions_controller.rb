class Admin::ApiVersionsController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, @site_admin_role)
  end

  # GET /api_versions
  # GET /api_versions.json
  def index
    @api_versions = ApiVersion.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @api_versions }
    end
  end

  # GET /api_versions/1
  # GET /api_versions/1.json
  def show
    @api_version = ApiVersion.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @api_version }
    end
  end

  # GET /api_versions/new
  # GET /api_versions/new.json
  def new
    @api_version = ApiVersion.new

    set_tabbed_translation_form_settings('advanced')

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @api_version }
    end
  end

  # GET /api_versions/1/edit
  def edit
    @api_version = ApiVersion.find(params[:id])
    set_tabbed_translation_form_settings('advanced')
  end

  # POST /api_versions
  # POST /api_versions.json
  def create
    @api_version = ApiVersion.new(params[:api_version])

    respond_to do |format|
      if @api_version.save
        format.html { redirect_to admin_api_versions_path, flash: {success:  t('app.msgs.success_created', :obj => t('mongoid.models.api_version'))} }
        format.json { render json: @api_version, status: :created, location: @api_version }
      else
        set_tabbed_translation_form_settings('advanced')
        format.html { render action: "new" }
        format.json { render json: @api_version.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /api_versions/1
  # PUT /api_versions/1.json
  def update
    @api_version = ApiVersion.find(params[:id])

    respond_to do |format|
      if @api_version.update_attributes(params[:api_version])
        format.html { redirect_to admin_api_versions_path, flash: {success:  t('app.msgs.success_updated', :obj => t('mongoid.models.api_version'))} }
        format.json { head :no_content }
      else
        set_tabbed_translation_form_settings('advanced')
        format.html { render action: "edit" }
        format.json { render json: @api_version.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /api_versions/1
  # DELETE /api_versions/1.json
  def destroy
    @api_version = ApiVersion.find(params[:id])
    @api_version.destroy

    respond_to do |format|
      format.html { redirect_to admin_api_versions_url, flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.api_version'))} }
      format.json { head :no_content }
    end
  end
end

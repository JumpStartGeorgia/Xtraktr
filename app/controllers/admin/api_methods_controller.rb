class Admin::ApiMethodsController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, @site_admin_role)
  end
  before_filter :load_api_version

  # GET /api_methods/1
  # GET /api_methods/1.json
  def show
    @api_method = ApiMethod.find(params[:id])

    @css.push('shCore.css', 'shThemeDefault.css', 'api.css')
    @js.push('shCore.js', 'shBrushJScript.js', 'api.js')

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @api_method }
    end
  end

  # GET /api_methods/new
  # GET /api_methods/new.json
  def new
    @api_method = ApiMethod.new

    set_tabbed_translation_form_settings('advanced')

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @api_method }
    end
  end

  # GET /api_methods/1/edit
  def edit
    @api_method = ApiMethod.find(params[:id])

    set_tabbed_translation_form_settings('advanced')
  end

  # POST /api_methods
  # POST /api_methods.json
  def create
    @api_method = ApiMethod.new(params[:api_method])

    respond_to do |format|
      if @api_method.save
        format.html { redirect_to admin_api_version_api_method_path(@api_version, @api_method), notice: t('app.msgs.success_created', :obj => t('mongoid.models.api_method')) }
        format.json { render json: @api_method, status: :created, location: @api_method }
      else
        set_tabbed_translation_form_settings('advanced')
        format.html { render action: "new" }
        format.json { render json: @api_method.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /api_methods/1
  # PUT /api_methods/1.json
  def update
    @api_method = ApiMethod.find(params[:id])

    respond_to do |format|
      if @api_method.update_attributes(params[:api_method])
        format.html { redirect_to admin_api_version_api_method_path(@api_version, @api_method), notice: t('app.msgs.success_updated', :obj => t('mongoid.models.api_method')) }
        format.json { head :no_content }
      else
        set_tabbed_translation_form_settings('advanced')
        format.html { render action: "edit" }
        format.json { render json: @api_method.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /api_methods/1
  # DELETE /api_methods/1.json
  def destroy
    @api_method = ApiMethod.find(params[:id])
    @api_method.destroy

    respond_to do |format|
      format.html { redirect_to admin_api_versions_url }
      format.json { head :no_content }
    end
  end

private

  def load_api_version
    @api_version = ApiVersion.find(params[:api_version_id])

    if @api_version.nil?
      redirect_to admin_api_path, :notice => t('app.msgs.does_not_exist')
    end
  end 
end

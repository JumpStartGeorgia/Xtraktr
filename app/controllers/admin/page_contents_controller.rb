class Admin::PageContentsController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, @site_admin_role)
  end
  
  # GET /pages
  # GET /pages.json
  def index
    @page_contents = PageContent.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @page_contents }
    end
  end

  # GET /pages/1
  # GET /pages/1.json
  def show
    @page_content = PageContent.find(params[:id])

    @css.push('api.css')

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @page_content }
    end
  end

  # GET /pages/new
  # GET /pages/new.json
  def new
    @page_content = PageContent.new

    set_tabbed_translation_form_settings('advanced')

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @page_content }
    end
  end

  # GET /pages/1/edit
  def edit
    @page_content = PageContent.find(params[:id])

    set_tabbed_translation_form_settings('advanced')
  end

  # POST /pages
  # POST /pages.json
  def create
    @page_content = PageContent.new(params[:page_content])

    respond_to do |format|
      if @page_content.save
        format.html { redirect_to admin_page_content_path(@page_content), flash: {success:  t('app.msgs.success_created', :obj => t('mongoid.models.page_content.one'))} }
        format.json { render json: @page_content, status: :created, location: @page_content }
      else
        set_tabbed_translation_form_settings('advanced')
        format.html { render action: "new" }
        format.json { render json: @page_content.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /pages/1
  # PUT /pages/1.json
  def update
    @page_content = PageContent.find(params[:id])

    @page_content.assign_attributes(params[:page_content])

    respond_to do |format|
      if @page_content.save
        format.html { redirect_to admin_page_content_path(@page_content), flash: {success:  t('app.msgs.success_updated', :obj => t('mongoid.models.page_content.one'))} }
        format.json { head :no_content }
      else
        set_tabbed_translation_form_settings('advanced')
        format.html { render action: "edit" }
        format.json { render json: @page_content.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pages/1
  # DELETE /pages/1.json
  def destroy
    @page_content = PageContent.find(params[:id])
    @page_content.destroy

    respond_to do |format|
      format.html { redirect_to admin_page_contents_url, flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.page_content.one'))} }
      format.json { head :no_content }
    end
  end
end

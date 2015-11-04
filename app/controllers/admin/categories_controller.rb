class Admin::CategoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, @site_admin_role)
  end

  # GET /categories
  # GET /categories.json
  def index
    @categories = Category.sorted

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @categories }
    end
  end

  # GET /categories/1
  # GET /categories/1.json
  def show
    @category = Category.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @category }
    end
  end

  # GET /categories/new
  # GET /categories/new.json
  def new
    @category = Category.new

    set_tabbed_translation_form_settings

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @category }
    end
  end

  # GET /categories/1/edit
  def edit
    @category = Category.find(params[:id])

    set_tabbed_translation_form_settings
  end

  # POST /categories
  # POST /categories.json
  def create
    @category = Category.new(params[:category])

    respond_to do |format|
      if @category.save
        format.html { redirect_to admin_categories_path, flash: {success:  t('app.msgs.success_created', :obj => t('mongoid.models.category.one'))} }
        format.json { render json: @category, status: :created, location: @category }
      else
        set_tabbed_translation_form_settings

        format.html { render action: "new" }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /categories/1
  # PUT /categories/1.json
  def update
    @category = Category.find(params[:id])

    respond_to do |format|
      if @category.update_attributes(params[:category])
        format.html { redirect_to admin_categories_path, flash: {success:  t('app.msgs.success_updated', :obj => t('mongoid.models.category.one'))} }
        format.json { head :no_content }
      else
        set_tabbed_translation_form_settings

        format.html { render action: "edit" }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /categories/1
  # DELETE /categories/1.json
  def destroy
    @category = Category.find(params[:id])
    @category.destroy

    respond_to do |format|
      format.html { redirect_to admin_categories_url, flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.category.one'))} }
      format.json { head :no_content }
    end
  end
end

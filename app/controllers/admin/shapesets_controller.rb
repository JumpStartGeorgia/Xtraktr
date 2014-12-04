class Admin::ShapesetsController < ApplicationController
  before_filter :authenticate_user!
  before_filter do |controller_instance|
    controller_instance.send(:valid_role?, User::ROLES[:admin])
  end

  # GET /shapesets
  # GET /shapesets.json
  def index
    @shapesets = Shapeset.sorted

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @shapesets }
    end
  end

  # GET /shapesets/1
  # GET /shapesets/1.json
  def show
    @shapeset = Shapeset.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @shapeset }
    end
  end

  # GET /shapesets/new
  # GET /shapesets/new.json
  def new
    @shapeset = Shapeset.new
    
    set_form_settings

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @shapeset }
    end
  end

  # GET /shapesets/1/edit
  def edit
    @shapeset = Shapeset.find(params[:id])
    
    set_form_settings
  end

  # POST /shapesets
  # POST /shapesets.json
  def create
    @shapeset = Shapeset.new(params[:shapeset])

    respond_to do |format|
      if @shapeset.save
        format.html { redirect_to admin_shapeset_path(@shapeset), notice: t('app.msgs.success_created', :obj => t('mongoid.models.shapeset')) }
        format.json { render json: @shapeset, status: :created, location: @shapeset }
      else
        set_form_settings
        format.html { render action: "new" }
        format.json { render json: @shapeset.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /shapesets/1
  # PUT /shapesets/1.json
  def update
    @shapeset = Shapeset.find(params[:id])

    @shapeset.assign_attributes(params[:shapeset])

    respond_to do |format|
      if @shapeset.save
        format.html { redirect_to admin_shapeset_path(@shapeset), notice: t('app.msgs.success_updated', :obj => t('mongoid.models.shapeset')) }
        format.json { head :no_content }
      else
        set_form_settings
        format.html { render action: "edit" }
        format.json { render json: @shapeset.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /shapesets/1
  # DELETE /shapesets/1.json
  def destroy
    @shapeset = Shapeset.find(params[:id])
    @shapeset.destroy

    respond_to do |format|
      format.html { redirect_to admin_shapesets_url }
      format.json { head :no_content }
    end
  end

private

  def set_form_settings
    @languages = Language.sorted
    @css.push('bootstrap-select.min.css', 'shapesets.css', 'select2.css')
    @js.push('bootstrap-select.min.js', 'shapesets.js', 'select2/select2.min.js')
    gon.tinymce_options = Hash[TinyMCE::Rails.configuration['default'].options.map{|(k,v)| [k.to_s,v.class == Array ? v.join(',') : v]}]
  end
end



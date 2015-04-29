class InterviewsController < ApplicationController
   def index
      respond_to do |format|
         format.html # index.html.erb
      end
   end


  def new
    @mod = Interview.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @mod }
    end
  end

  def create
    @mod = Interview.new(params[:interview])
    @file_id = params[:download_file_id]
    @url = Dataset.find(@file_id).datafile.url 
    @model_name = @mod.model_name.downcase
    respond_to do |format|
      if @mod.save

        @mapper = FileMapper.create({file: @file_id })
        format.js {render action: "create" , status: :ok }
        #format.html { redirect_to interview_path, notice: t('app.msgs.success_created', :obj => t('mongoid.models.user')) }
        #format.json { render json: @mod, status: :created, location: @mod }
      else
        # format.html { render action: "new" }
        @errors = @mod.errors.to_json
        format.js {render action: "missing" , status: :ok }
        # format.json { render json: @mod.errors, status: :unprocessable_entity }
      end
    end
  end
end

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
        @mapper = FileMapper.create({ file: @file_id })         
        format.js {render action: "create" , status: :ok, :locals => { :ok => true }}
      else
        @errors = @mod.errors.to_json
        format.js {render action: "create" , status: :precondition_failed  }
      end
    end
  end  
end

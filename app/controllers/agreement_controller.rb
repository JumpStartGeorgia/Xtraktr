class AgreementsController < ApplicationController

  def new
    @mod = Agreement.new

    respond_to do |format|
      format.html render :partial => 'form'
      format.json { render json: @mod }
    end
  end

  def create
    @mod = Agreement.new(params[:agreement])
    @file_id = params[:download_file_id]
    @file_type = params[:download_file_type]
    @url = Dataset.find(@file_id).datafile.url 
    @model_name = @mod.model_name.downcase
    respond_to do |format|
      if @mod.save
        @mapper = FileMapper.create({ file: @file_id, file_type: @file_type })         
        format.js {render action: "create" , status: :ok, :locals => { :ok => true }}
      else
        @errors = @mod.errors.to_json
        format.js {render action: "create" , status: :precondition_failed  }
      end
    end
  end  
end

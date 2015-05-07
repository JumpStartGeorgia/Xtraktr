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

    # @file_id = params[:download_file_id]
    # @file_type = params[:download_file_type]
    @url = Dataset.find(@mod.dataset_id).urls[@mod.dataset_type][@mod.dataset_locale]
    @model_name = @mod.model_name.downcase
    respond_to do |format|
      if @mod.save
        @mapper = FileMapper.create({ dataset_id: @mod.dataset_id, dataset_type: @mod.dataset_type, dataset_locale: @mod.dataset_locale })         
        format.js {render action: "create" , status: :ok, :locals => { :ok => true }}
      else
        @errors = @mod.errors.to_json
        format.js {render action: "create" , status: :precondition_failed  }
      end
    end
  end  
end

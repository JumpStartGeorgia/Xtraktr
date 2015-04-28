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

    respond_to do |format|
      if params[:terms] == "1" && @mod.save
        format.html { redirect_to interview_path, notice: t('app.msgs.success_created', :obj => t('mongoid.models.user')) }
        format.json { render json: @mod, status: :created, location: @mod }
      else
        format.html { render action: "new" }
        format.json { render json: @mod.errors, status: :unprocessable_entity }
      end
    end
  end
end

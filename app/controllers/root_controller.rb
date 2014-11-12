class RootController < ApplicationController

  layout "explore_data", only: [:explore_data_show]

  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def explore_data
    @datasets = Dataset.is_public.sorted

    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  def explore_data_show
    @dataset = Dataset.is_public.find_by(id: params[:id])

    if @dataset.blank?
      redirect_to explore_data_path, :notice => t('app.msgs.does_not_exist')
    else
      @is_admin = false
      @dataset_url = explore_data_show_path(@dataset)
      gon.explore_data = true
      gon.explore_data_ajax_path = explore_data_show_path(:format => :js)

      # this method is in application_controller
      # and gets all of the required information
      # and responds appropriately to html or js
      explore_data_generator(@dataset)
    end
  end
  


end

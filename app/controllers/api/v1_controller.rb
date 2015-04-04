class Api::V1Controller < ApplicationController

  def index

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def documentation

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  ########################################
  ## DATASETS
  ########################################

  # get list of all public datasets
  def dataset_catalog
    respond_to do |format|
      format.json { 
        render json: ApiV1.dataset_catalog, each_serializer: DatasetCatalogSerializer
      }
    end
  end

  # get details about a dataset
  def dataset
    respond_to do |format|
      format.json { 
        render json: ApiV1.dataset(params[:dataset_id]), each_serializer: DatasetSerializer
      }
    end
  end

  # get codebook for a dataset
  def dataset_codebook
    respond_to do |format|
      format.json { 
        render json: ApiV1.dataset_codebook(params[:dataset_id]), each_serializer: QuestionSerializer
      }
    end
  end


  ########################################
  ## TIME SERIES
  ########################################

  # get list of all public time sereie
  def time_series_catalog
    respond_to do |format|
      format.json { 
        render json: ApiV1.time_series_catalog, each_serializer: TimeSeriesCatalogSerializer
      }
    end
  end

  # get details about a time_series
  def time_series
    respond_to do |format|
      format.json { 
        render json: ApiV1.time_series(params[:time_series_id]), each_serializer: TimeSeriesSerializer
      }
    end
  end

  # get codebook for a time_series
  def time_series_codebook
    respond_to do |format|
      format.json { 
        render json: ApiV1.time_series_codebook(params[:time_series_id]), each_serializer: TimeSeriesQuestionSerializer
      }
    end
  end
end

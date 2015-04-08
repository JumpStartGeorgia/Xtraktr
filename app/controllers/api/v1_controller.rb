class Api::V1Controller < ApplicationController
  before_filter :restrict_access, except: [:index, :documentation]
  after_filter :record_request, except: [:index, :documentation]

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
        render json: ApiV1.dataset_catalog, each_serializer: DatasetCatalogSerializer, root: 'datasets'
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
        render json: ApiV1.dataset_codebook(params[:dataset_id]), each_serializer: QuestionSerializer, root: 'questions'
      }
    end
  end

  # analyse the dataset for the passed in parameters
  # parameters:
  #  - question_code - code of question to analyze (required)
  #  - broken_down_by_code - code of question to compare against the first question (optional)
  #  - filt_by_code - code of question to filter the anaylsis by (optioanl)
  #  - can_exclude - boolean indicating if the can_exclude answers should by excluded (optional, default false)
  def dataset_analysis
    respond_to do |format|
      format.json { 
        render json: ApiV1.dataset_analysis(params[:dataset_id], params[:question_code], params)
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
        render json: ApiV1.time_series_catalog, each_serializer: TimeSeriesCatalogSerializer, root: 'time_series'
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
        render json: ApiV1.time_series_codebook(params[:time_series_id]), each_serializer: TimeSeriesQuestionSerializer, root: 'questions'
      }
    end
  end



private
  # make sure the access token is valid
  def restrict_access
    @user_api_key = ApiKey.find_by(key: params[:access_token])
    if @user_api_key.nil?
      render json: {errors: [{status: '401', detail: I18n.t('api.msgs.no_key') }]}
      return false
    end
  end

  # record the api request
  def record_request
    ApiRequest.record_request(@user_api_key, request.remote_ip, request.filtered_parameters, @user_agent)
  end
end

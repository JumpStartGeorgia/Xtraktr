class Api::V1Controller < ApplicationController
  before_filter :restrict_access, except: [:index, :documentation]
  before_filter :set_background
  after_filter :record_request, except: [:index, :documentation]
  


  def index
    redirect_to api_path
  end

  def documentation
    
    redirect = false
    redirect = params[:method].nil?

    if !redirect
      v = request.path.split('/')[3]
      m = request.path.split('/').last
      # see if version exists
      @api_version = ApiVersion.is_public.by_permalink(v)
      # see if method exists
      @api_method = ApiMethod.is_public.by_permalink(@api_version.id, m) if @api_version.present?

      redirect = @api_method.nil?
    end

    if redirect
      redirect_to api_path, :notice => t('app.msgs.does_not_exist')
    else
      @css.push('shCore.css', 'shThemeDefault.css', 'api.css')
      @js.push('shCore.js', 'shBrushJScript.js', 'api.js')

      respond_to do |format|
        format.html {render 'api/documentation'}
      end
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
        render json: ApiV1.dataset(params[:dataset_id], cleaned_filtered_params(request.filtered_parameters)), each_serializer: DatasetSerializer
      }
    end
  end

  # get codebook for a dataset
  def dataset_codebook
    respond_to do |format|
      format.json { 
        render json: ApiV1.dataset_codebook(params[:dataset_id], cleaned_filtered_params(request.filtered_parameters)), each_serializer: QuestionSerializer, root: 'questions'
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
        render json: ApiV1.dataset_analysis(params[:dataset_id], params[:question_code], cleaned_filtered_params(request.filtered_parameters))
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
        render json: ApiV1.time_series(params[:time_series_id], cleaned_filtered_params(request.filtered_parameters)), each_serializer: TimeSeriesSerializer
      }
    end
  end

  # get codebook for a time_series
  def time_series_codebook
    respond_to do |format|
      format.json { 
        render json: ApiV1.time_series_codebook(params[:time_series_id], cleaned_filtered_params(request.filtered_parameters)), each_serializer: TimeSeriesQuestionSerializer, root: 'questions'
      }
    end
  end

  # analyse the time series for the passed in parameters
  # parameters:
  #  - question_code - code of question to analyze (required)
  #  - filt_by_code - code of question to filter the anaylsis by (optioanl)
  #  - can_exclude - boolean indicating if the can_exclude answers should by excluded (optional, default false)
  def time_series_analysis
    respond_to do |format|
      format.json { 
        render json: ApiV1.time_series_analysis(params[:time_series_id], params[:question_code], cleaned_filtered_params(request.filtered_parameters))
      }
    end
  end



private
  # remove unwanted items from the filtered params
  def cleaned_filtered_params(params)
    params.except('access_token', 'controller', 'action', 'format', 'locale')
  end

  # make sure the access token is valid
  def restrict_access
    if !@is_xtraktr
      @user_api_key = ApiKey.find_by(key: params[:access_token])
      if @user_api_key.nil?
        render json: {errors: [{status: '401', detail: I18n.t('api.msgs.no_key') }]}
        return false
      end
    end
  end

  # record the api request
  def record_request
    ApiRequest.record_request(@user_api_key, request.remote_ip, request.filtered_parameters, @user_agent)
  end

  def set_background
    @show_subnav_navbar = true
    @show_title = false
    @api = true
  end

end

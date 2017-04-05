class Api::V3Controller < ApplicationController
  before_filter :restrict_access, except: [:index, :documentation]
  before_filter :set_background
  after_filter :record_request, except: [:index, :documentation]



  def index
    redirect_to api_path
  end

  def documentation
    @klass=@klass_footer=' white'
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
        render json: Api::V3.dataset_catalog, each_serializer: DatasetCatalogSerializer, root: 'datasets', callback: params[:callback]
      }
    end
  end

  # get details about a dataset
  def dataset
    respond_to do |format|
      format.json {
        render json: Api::V3.dataset(params[:dataset_id], clean_filtered_params(request.filtered_parameters)), serializer: DatasetSerializer, callback: params[:callback]
      }
    end
  end

  # get data for datasets question
  def dataset_question_data
    respond_to do |format|
      format.json {
        render json: Api::V3.dataset_question_data(params[:dataset_id], params[:question_code], clean_filtered_params(request.filtered_parameters)), callback: params[:callback]
      }
    end
  end

  # get codebook for a dataset
  def dataset_codebook
    respond_to do |format|
      format.json {
        render json: Api::V3.dataset_codebook(params[:dataset_id], clean_filtered_params(request.filtered_parameters)), serializer: DatasetCodebookSerializer, callback: params[:callback]
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
        render json: Api::V3.dataset_analysis(params[:dataset_id], params[:question_code], clean_filtered_params(request.filtered_parameters)), callback: params[:callback]
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
        render json: Api::V3.time_series_catalog, each_serializer: TimeSeriesCatalogSerializer, root: 'time_series', callback: params[:callback]
      }
    end
  end

  # get details about a time_series
  def time_series
    respond_to do |format|
      format.json {
        render json: Api::V3.time_series(params[:time_series_id], clean_filtered_params(request.filtered_parameters)), serializer: TimeSeriesSerializer, callback: params[:callback]
      }
    end
  end

  # get codebook for a time_series
  def time_series_codebook
    respond_to do |format|
      format.json {
        render json: Api::V3.time_series_codebook(params[:time_series_id], clean_filtered_params(request.filtered_parameters)), serializer: TimeSeriesCodebookSerializer, callback: params[:callback]
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
        render json: Api::V3.time_series_analysis(params[:time_series_id], params[:question_code], clean_filtered_params(request.filtered_parameters)), callback: params[:callback]
      }
    end
  end



private
  # remove unwanted items from the filtered params
  def clean_filtered_params(params)
    params.except('access_token', 'controller', 'action', 'format', 'locale')
  end

  # make sure the access token is valid
  def restrict_access
    @user_api_key = ApiKey.find_by(key: params[:access_token])
    if @user_api_key.nil?
      render json: {errors: [{status: '401', detail: I18n.t('api.msgs.no_key', url: new_user_session_url) }]}
      return false
    end
  end

  # record the api request
  def record_request
    ApiRequest.record_request(@user_api_key, request.remote_ip, request.filtered_parameters, @user_agent)
  end

  def set_background
    @show_title = false
    @api = true
  end

end

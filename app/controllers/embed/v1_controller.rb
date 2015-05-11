class Embed::V1Controller < ApplicationController

  layout 'embed'


  # show the embed chart if the id was provided and can be decoded and parsed into hash
  # id - base64 encoded string of a hash of parameters
  def index
    redirect = params[:id].nil?
    options = nil

    begin
      options = Rack::Utils.parse_query(Base64.urlsafe_decode64(params[:id]))
    rescue
      redirect = true
    end

    # options must be present with dataset or time series id and question code; all other options are not required
    if !redirect && options.present? && (options['dataset_id'].present? || options['time_series_id'].present?) && options['question_code'].present?

      if options['dataset_id'].present?
        data = ApiV1.dataset_analysis(options['dataset_id'], options['question_code'], clean_filtered_params(options))

        # save dataset title
        @title = data[:dataset][:title] if data.present? && data[:dataset].present?
      elsif options['time_series_id'].present?
        data = ApiV1.time_series_analysis(options['time_series_id'], options['question_code'], clean_filtered_params(options))

        # save dataset title
        @title = data[:time_series][:title] if data.present? && data[:time_series].present?
      end

      # save data to gon so can be used for charts
      gon.json_data = data
      # save values of filters so can choose correct chart/map to show
      gon.broken_down_by_value = options['broken_down_by_value'] if options['broken_down_by_value'].present? # only present if doing maps
      gon.filtered_by_value = options['filtered_by_value'] if options['filtered_by_value'].present?

      set_gon_highcharts

      # if the visual is a chart, include the highcharts file
      # if the visual is a map, include the highmaps file
      gon.visual_type = options['visual_type']
      if options['visual_type'] == 'chart'
        @js.push('highcharts.js')
      elsif options['visual_type'] == 'map'
        @js.push('highcharts.js', 'highcharts-map.js')

        if options['dataset_id'].present?
          # have to get the shape file url for this dataset
          @shapes_url = Dataset.shape_file_url(options['dataset_id'])
        end
      end
      @js.push('highcharts-exporting.js')

      respond_to do |format|
        format.html # index.html.erb
      end

    else
      redirect_to root_path
    end

  end

end
class Embed::V1Controller < ApplicationController

  layout 'embed'


  # show the embed chart if the id was provided and can be decoded and parsed into hash
  # id - base64 encoded string of a hash of parameters
  def index
    @highlight_data = get_highlight_data(params[:id])

    if !@highlight_data[:error]
      # save the js data into gon
      gon.highlight_data = {}
      gon.highlight_data[@highlight_data[:highlight_id].to_s] = @highlight_data[:js]

      set_gon_highcharts

      gon.update_page_title = true

      # if the visual is a chart, include the highcharts file
      # if the visual is a map, include the highmaps file
      gon.visual_type = @highlight_data[:visual_type]
      if @highlight_data[:visual_type] == 'chart'
        @js.push('highcharts.js')
      elsif @highlight_data[:visual_type] == 'map'
        @js.push('highcharts.js', 'highcharts-map.js')

        if @highlight_data[:type] == 'dataset'
          # have to get the shape file url for this dataset
          @shapes_url = Dataset.shape_file_url(options['dataset_id'])
        end
      end
      @js.push('highcharts-exporting.js')

    end

    respond_to do |format|
      format.html # index.html.erb
    end

  end


  def index_old
    options = nil
    @errors = false

    begin
      options = Rack::Utils.parse_query(Base64.urlsafe_decode64(params[:id]))
    rescue
      @errors = true
    end

    # options must be present with dataset or time series id and question code; all other options are not required
    if !@errors && options.present? && (options['dataset_id'].present? || options['time_series_id'].present?) && options['question_code'].present?
      options = clean_filtered_params(options)

      if options['dataset_id'].present?
        data = ApiV1.dataset_analysis(options['dataset_id'], options['question_code'], options)

        # save dataset title
        @title = data[:dataset][:title] if data.present? && data[:dataset].present?

        # create link to dashboard
        @link = explore_data_dashboard_url(options['dataset_id'])

        # create link to this item
        options['id'] = options['dataset_id']
        options['from_embed'] = true
        gon.visual_link = explore_data_show_url(options)

      elsif options['time_series_id'].present?
        data = ApiV1.time_series_analysis(options['time_series_id'], options['question_code'], options)

        # save dataset title
        @title = data[:time_series][:title] if data.present? && data[:time_series].present?

        # create link to dashboard
        @link = explore_time_series_dashboard_url(options['time_series_id'])

        # create link to this item
        options['id'] = options['time_series_id']
        options['from_embed'] = true
        gon.visual_link = explore_time_series_show_url(options)
        
      end

      # check if errors exist
      @errors = data[:errors].present?

      if !@errors 
        # save data to gon so can be used for charts
        gon.json_data = data
        # save values of filters so can choose correct chart/map to show
        gon.broken_down_by_value = options['broken_down_by_value'] if options['broken_down_by_value'].present? # only present if doing maps
        gon.filtered_by_value = options['filtered_by_value'] if options['filtered_by_value'].present?

        set_gon_highcharts

      end

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

    end

    respond_to do |format|
      format.html # index.html.erb
    end
  end

end
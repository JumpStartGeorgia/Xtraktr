class Embed::V3Controller < ApplicationController

  layout 'embed'


  # show the embed chart if the id was provided and can be decoded and parsed into hash
  # id - base64 encoded string of a hash of parameters
  def index
    @highlight_data = get_highlight_data(params[:id])
    puts @highlight_data.inspect
    if !@highlight_data[:error]
    puts "here"
      # save the js data into gon
      gon.highlight_data = {}
      gon.highlight_data[@highlight_data[:highlight_id].to_s] = @highlight_data[:js]

      set_gon_highcharts

      gon.update_page_title = true

      gon.get_highlight_desc_link = highlights_get_description_path
      gon.powered_by_link = @xtraktr_url
      gon.powered_by_text = I18n.t('app.common.powered_by_xtraktr')
      gon.powered_by_title = I18n.t('app.common.powered_by_xtraktr_title')
      
      gon.visual_type = @highlight_data[:visual_type]
      if @highlight_data[:visual_type] != Highlight::VISUAL_TYPES[:map] # if the visual is a chart, include the highcharts file
        @js.push('highcharts.js')
      elsif @highlight_data[:visual_type] == Highlight::VISUAL_TYPES[:map] # if the visual is a map, include the highmaps file
        @js.push('highcharts.js', 'highcharts-map.js')

        if @highlight_data[:type] == 'dataset'
          @shapes_url = Dataset.shape_file_url(@highlight_data[:id]) # have to get the shape file url for this dataset
        end
      end
      @js.push('highcharts-exporting.js')
    end
    puts "here1"
    respond_to do |format|
      format.html # index.html.erb
    end
  end
end

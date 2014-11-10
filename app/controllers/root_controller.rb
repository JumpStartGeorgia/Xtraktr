class RootController < ApplicationController

  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def explore_data
    @datasets = Dataset.is_public.basic_info

    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  def explore_data_show
    @dataset = Dataset.find_by(id: params[:id])

    if @dataset.blank?
      redirect_to explore_data_path, :notice => t('app.msgs.does_not_exist')
    else
      # the questions for cross tab can only be those that have code answers
      @questions = @dataset.questions.with_code_answers

      # initialize variables
      # start with a random question
      @row = @questions.map{|x| x.code}.sample
      @col = nil
      @filter = nil

      # check to make sure row and col param is in list of questions, if provided
      if params[:row].present? && @questions.index{|x| x.code == params[:row]}.present?
        @row = params[:row]
      end
      if params[:col].present? && @questions.index{|x| x.code == params[:col]}.present?
        @col = params[:col]
      end

      # check for valid filter values
      if params[:filter_variable].present? && params[:filter_value].present? &&
        q = @questions.select{|x| x.code.to_s == params[:filter_variable]}.first
        a = q.answers.with_value(params[:filter_value]) if q.present?
        
        if q.present? && a.present?
          @filter = {code: params[:filter_variable], value: params[:filter_value], name: q.text, answer: a.text }
        end
      end

      respond_to do |format|
        format.html{
          # load the shapes if needed
          if @dataset.is_mappable?
            @shapes_url = @dataset.js_shapefile_url_path
          end

          # add the required assets
          @css.push('bootstrap-select.min.css', "explore_data.css")
          @js.push('bootstrap-select.min.js', "explore_data.js", 'highcharts.js', 'highcharts-map.js', 'highcharts-exporting.js')

          # record javascript variables
          gon.explore_data = true
          gon.explore_data_ajax_path = explore_data_show_path(:format => :js)
          gon.hover_region = I18n.t('root.explore_data_show.hover_region')
          gon.na = I18n.t('root.explore_data_show.na')
          gon.percent = I18n.t('root.explore_data_show.percent')
          gon.datatable_copy_title = I18n.t('datatable.copy.title')
          gon.datatable_copy_tooltip = I18n.t('datatable.copy.tooltip')
          gon.datatable_csv_title = I18n.t('datatable.csv.title')
          gon.datatable_csv_tooltip = I18n.t('datatable.csv.tooltip')
          gon.datatable_xls_title = I18n.t('datatable.xls.title')
          gon.datatable_xls_tooltip = I18n.t('datatable.xls.tooltip')
          gon.datatable_pdf_title = I18n.t('datatable.pdf.title')
          gon.datatable_pdf_tooltip = I18n.t('datatable.pdf.tooltip')
          gon.datatable_print_title = I18n.t('datatable.print.title')
          gon.datatable_print_tooltip = I18n.t('datatable.print.tooltip')
          gon.highcharts_context_title = I18n.t('highcharts.context_title')
          gon.highcharts_png = I18n.t('highcharts.png')
          gon.highcharts_jpg = I18n.t('highcharts.jpg')
          gon.highcharts_pdf = I18n.t('highcharts.pdf')
          gon.highcharts_svg = I18n.t('highcharts.svg')
        } 
        format.js{
          # get the data
          options = {}
          options[:filter] = @filter if @filter.present?
          options[:exclude_dkra] = params[:exclude_dkra].to_bool if params[:exclude_dkra].present?

          # if @col has data, then this is a crosstab,
          # else this is just a single variable lookup
          if @col.present?
            @data = @dataset.data_crosstab_analysis(@row, @col, options)
            @data[:title] = {}
            @data[:title][:html] = build_crosstab_title_html(@data[:row_question], @data[:column_question], @filter, @data[:total_responses])
            @data[:title][:text] = build_crosstab_title_text(@data[:row_question], @data[:column_question], @filter, @data[:total_responses])
            # create special map titles so filter of column can be shown in title
            # test to see which variable is mappable - that one must go in as the row for the map title
            row_index = @questions.select{|x| x.code == params[:row] && x.is_mappable?}
            if row_index.present?
              @data[:title][:map_html] = build_crosstab_map_title_html(@data[:row_question], @data[:column_question], @filter, @data[:total_responses])
              @data[:title][:map_text] = build_crosstab_map_title_text(@data[:row_question], @data[:column_question], @filter, @data[:total_responses])
            else
              @data[:title][:map_html] = build_crosstab_map_title_html(@data[:column_question], @data[:row_question], @filter, @data[:total_responses])
              @data[:title][:map_text] = build_crosstab_map_title_text(@data[:column_question], @data[:row_question], @filter, @data[:total_responses])
            end
          else
            @data = @dataset.data_onevar_analysis(@row, options)
            @data[:title] = {}
            @data[:title][:html] = build_onevar_title_html(@data[:row_question], @filter, @data[:total_responses])
            @data[:title][:text] = build_onevar_title_text(@data[:row_question], @filter, @data[:total_responses])
            @data[:title][:map_html] = @data[:title][:html]
            @data[:title][:map_text] = @data[:title][:text]
          end
          @data[:subtitle] = {}
          @data[:subtitle][:html] = build_subtitle_html(@data[:total_responses])
          @data[:subtitle][:text] = build_subtitle_text(@data[:total_responses])

  #        logger.debug "/////////////////////////// #{@data}"

          status = @data.present? ? :ok : :unprocessable_entity
          render json: @data.to_json, status: :ok

        }
      end   
    end

  end
  

private

  def build_crosstab_title_html(row, col, filter, total)
    title = t('root.explore_data_show.crosstab.html.title', :row => row, :col => col)
    if filter.present?
      title << t('root.explore_data_show.crosstab.html.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title.html_safe
  end 

  def build_crosstab_title_text(row, col, filter, total)
    title = t('root.explore_data_show.crosstab.text.title', :row => row, :col => col)
    if filter.present?
      title << t('root.explore_data_show.crosstab.text.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title
  end 

  def build_crosstab_map_title_html(row, col, filter, total)
    title = t('root.explore_data_show.crosstab.html.map.title', :row => row)
    title << t('root.explore_data_show.crosstab.html.map.title_col', :col => col)
    if filter.present?
      title << t('root.explore_data_show.crosstab.html.map.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title.html_safe
  end 

  def build_crosstab_map_title_text(row, col, filter, total)
    title = t('root.explore_data_show.crosstab.text.map.title', :row => row)
    title << t('root.explore_data_show.crosstab.text.map.title_col', :col => col)
    if filter.present?
      title << t('root.explore_data_show.crosstab.text.map.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title
  end 

  def build_onevar_title_html(row, filter, total)
    title = t('root.explore_data_show.onevar.html.title', :row => row)
    if filter.present?
      title << t('root.explore_data_show.onevar.html.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title.html_safe
  end 

  def build_onevar_title_text(row, filter, total)
    title = t('root.explore_data_show.onevar.text.title', :row => row)
    if filter.present?
      title << t('root.explore_data_show.onevar.text.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title
  end 

  def build_subtitle_html(total)
    title = "<br /> <span class='total_responses'>"
    title << t('root.explore_data_show.subtitle.html', :num => view_context.number_with_delimiter(total))
    title << "</span>"
    return title.html_safe
  end 

  def build_subtitle_text(total)
    return t('root.explore_data_show.subtitle.text', :num => view_context.number_with_delimiter(total))
  end 

end

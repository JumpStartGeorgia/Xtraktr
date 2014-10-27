class RootController < ApplicationController

  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def explore_data
    dataset = Dataset.first

    # the questions for cross tab can only be those that have code answers
    @questions = dataset.question_with_code_answers

    @filter_answers = dataset.answers

    # initialize variables
    # start with a random question
    @row = @questions.keys.sample
    @col = nil
    @filter = nil

    # check to make sure row and col param is in list of questions, if provided
    if params[:row].present? && @questions.keys.index{|k| k == params[:row]}.present?
      @row = params[:row]
    end
    if params[:col].present? && @questions.keys.index{|k| k == params[:col]}.present?
      @col = params[:col]
    end

    # check for valid filter values
    if params[:filter_variable].present? && params[:filter_value].present? &&
      q_index = @questions.keys.index{|k| k == params[:filter_variable]}
      a_index = @filter_answers.index{|k, v| k == params[:filter_variable] && v['value'].to_s == params[:filter_value]}
      
      if q_index.present? && a_index.present?
        @filter = {code: params[:filter_variable], value: params[:filter_value], name: @questions[q_index]['text'], answer: @filter_answers[a_index]['text'] }
      end       
    end

    respond_to do |format|
      format.html{
        # load the region shapes
        @use_map = true

        # add the required assets
        @css.push('bootstrap-select.min.css', "explore_data.css")
        @js.push('bootstrap-select.min.js', "explore_data.js", 'highcharts.js', 'highcharts-map.js', 'highcharts-exporting.js')

        # record url for making ajax call
        gon.explore_data = true
        gon.explore_data_ajax_path = explore_data_path(:format => :js)
        gon.hover_region = I18n.t('root.explore_data.hover_region')
        gon.na = I18n.t('root.explore_data.na')
        gon.percent = I18n.t('root.explore_data.percent')
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
          @data = dataset.data_crosstab_analysis(@row, @col, options)
          @data[:title] = {}
          @data[:title][:html] = build_crosstab_title_html(@data[:row_question], @data[:column_question], @filter, @data[:total_responses])
          @data[:title][:text] = build_crosstab_title_text(@data[:row_question], @data[:column_question], @filter, @data[:total_responses])
          # create special map titles so filter of column can be shown in title
          # test to see which variable is mappable - that one must go in as the row for the map title
          q = @questions.select{|k,v| k == params[:row] && v['is_mappable'] == true}
          if q.present?
            @data[:title][:map_html] = build_crosstab_map_title_html(@data[:row_question], @data[:column_question], @filter, @data[:total_responses])
            @data[:title][:map_text] = build_crosstab_map_title_text(@data[:row_question], @data[:column_question], @filter, @data[:total_responses])
          else
            @data[:title][:map_html] = build_crosstab_map_title_html(@data[:column_question], @data[:row_question], @filter, @data[:total_responses])
            @data[:title][:map_text] = build_crosstab_map_title_text(@data[:column_question], @data[:row_question], @filter, @data[:total_responses])
          end
        else
          @data = dataset.data_onevar_analysis(@row, options)
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
  

private

  def build_crosstab_title_html(row, col, filter, total)
    title = t('root.explore_data.crosstab.html.title', :row => row, :col => col)
    if filter.present?
      title << t('root.explore_data.crosstab.html.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title.html_safe
  end 

  def build_crosstab_title_text(row, col, filter, total)
    title = t('root.explore_data.crosstab.text.title', :row => row, :col => col)
    if filter.present?
      title << t('root.explore_data.crosstab.text.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title
  end 

  def build_crosstab_map_title_html(row, col, filter, total)
    title = t('root.explore_data.crosstab.html.map.title', :row => row)
    title << t('root.explore_data.crosstab.html.map.title_col', :col => col)
    if filter.present?
      title << t('root.explore_data.crosstab.html.map.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title.html_safe
  end 

  def build_crosstab_map_title_text(row, col, filter, total)
    title = t('root.explore_data.crosstab.text.map.title', :row => row)
    title << t('root.explore_data.crosstab.text.map.title_col', :col => col)
    if filter.present?
      title << t('root.explore_data.crosstab.text.map.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title
  end 

  def build_onevar_title_html(row, filter, total)
    title = t('root.explore_data.onevar.html.title', :row => row)
    if filter.present?
      title << t('root.explore_data.onevar.html.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title.html_safe
  end 

  def build_onevar_title_text(row, filter, total)
    title = t('root.explore_data.onevar.text.title', :row => row)
    if filter.present?
      title << t('root.explore_data.onevar.text.title_filter', :variable => filter[:name], :value => filter[:answer] )
    end
    return title
  end 

  def build_subtitle_html(total)
    title = "<br /> <span class='total_responses'>"
    title << t('root.explore_data.subtitle.html', :num => total)
    title << "</span>"
    return title.html_safe
  end 

  def build_subtitle_text(total)
    return t('root.explore_data.subtitle.text', :num => total)
  end 

end

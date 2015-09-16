class Api::V1
  extend ActionView::Helpers::NumberHelper
  ANALYSIS_TYPE = {:single => 'single', :comparative => 'comparative', :time_series => 'time_series'}

  ########################################
  ## DATASETS
  ########################################

  # get list of all datasets
  def self.dataset_catalog
    Dataset.is_public.sorted
  end

  # get details about a dataset
  # parameters:
  #  - dataset_id - id of dataset to get info on (required)
  #  - language - locale of language to get data in (optional)
  def self.dataset(dataset_id, options={})
    if dataset_id.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.missing_required_params') }]}
    end

    # get options
    language = options['language'].present? ? options['language'].downcase : nil

    # get dataset
    dataset = Dataset.is_public.find(dataset_id)

    if dataset.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_dataset') }]}
    end

    # if language provided, set it
    if language.present? && dataset.languages.include?(language)
      dataset.current_locale = language
    end

    return dataset
  end

  # get codebook for a dataset
  # parameters:
  #  - dataset_id - id of dataset to get codebook for (required)
  #  - language - locale of language to get data in (optional)
  def self.dataset_codebook(dataset_id, options={})
    questions = nil

    if dataset_id.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.missing_required_params') }]}
    end

    # get options
    language = options['language'].present? ? options['language'].downcase : nil

    # get dataset
    dataset = Dataset.is_public.find(dataset_id)

    if dataset.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_dataset') }]}
    end

    # if language provided, set it
    if language.present? && dataset.languages.include?(language)
      dataset.current_locale = language
    end

    questions = dataset.questions.for_analysis

    return questions
  end


  # analyse the dataset for the passed in parameters
  # parameters:
  #  - dataset_id - id of dataset to analyze (required)
  #  - question_code - code of question to analyze (required)
  #  - broken_down_by_code - code of question to compare against the first question (optional)
  #  - filtered_by_code - code of question to filter the analysis by (optioanl)
  #  - can_exclude - boolean indicating if the can_exclude answers should by excluded (optional, default false)
  #  - with_title - boolean indicating if results should include title (optional, default false)
  #  - with_chart_data - boolean indicating if results should include data formatted for highcharts (optional, default false)
  #  - with_map_data - boolean indicating if results should include data formatted for highmaps (optional, default false)
  #  - language - locale of language to get data in (optional)
  # return format:
  # {
  #   dataset: {id, title},
  #   question: {code, original_code, text, is_mappable, answers: [{value, text, can_exclude, sort_order}]},
  #   broken_down_by: {code, original_code, text, answers: [{value, text, can_exclude}]} (optional),
  #   filtered_by: {code, original_code, text, answers: [{value, text, can_exclude}]} (optional),
  #   analysis_type: single/comparative (single means results will be hash while comparative means results will be array)
  #   results: {title, total_responses, analysis: [{answer_value, answer_text, count, percent}, ...]}
  #   chart: {title, data: [{name, y(percent), count, answer_value}, ...] } (optional)
  #   map: {question_code, title, data: [{shape_name, display_name, value, count}, ...] } (optional)
  #   errors: [{status, detail}] (optional)
  # }
  def self.dataset_analysis(dataset_id, question_code, options={})
    data = {}

    if dataset_id.nil? || question_code.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.missing_required_params') }]}
    end

    # get options
    private_user_id = options['private_user_id'].present? ? options['private_user_id'] : nil
    can_exclude = options['can_exclude'].present? && options['can_exclude'].to_bool == true
    with_title = options['with_title'].present? && options['with_title'].to_bool == true
    with_chart_data = options['with_chart_data'].present? && options['with_chart_data'].to_bool == true
    with_map_data = options['with_map_data'].present? && options['with_map_data'].to_bool == true
    language = options['language'].present? ? options['language'].downcase : nil

    dataset = nil
    if private_user_id
      # decode the id
      begin
        user_id = Base64.urlsafe_decode64(private_user_id)
      end
      # get the dataset
      dataset = Dataset.by_id_for_owner(dataset_id, user_id, user_id) if user_id.present?
    else
      dataset = Dataset.is_public.find(dataset_id)
    end

    # if the dataset could not be found, stop
    if dataset.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_dataset') }]}
    end

    # if language provided, set it
    if language.present? && dataset.languages.include?(language)
      dataset.current_locale = language
    end

    # get the questions
    question = dataset.questions.with_code(question_code)

    # if the question could not be found, stop
    if question.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_question') }]}
    end

    # if filter by by exists, get it
    filtered_by = nil
    if options['filtered_by_code'].present?
      filtered_by = dataset.questions.with_code(options['filtered_by_code'].strip)

      # if the filter by question could not be found, stop
      if filtered_by.nil?
        return {errors: [{status: '404', detail: I18n.t('api.msgs.no_filtered_by') }]}
      end
    end

    # if broken down by exists, get it
    broken_down_by = nil
    if options['broken_down_by_code'].present?
      broken_down_by = dataset.questions.with_code(options['broken_down_by_code'].strip)

      # if the broken_down_by by question could not be found, stop
      if broken_down_by.nil?
        return {errors: [{status: '404', detail: I18n.t('api.msgs.no_broken_down_by') }]}
      end
    end

    ########################
    # start populating the output
    data[:dataset] = {id: dataset.id, title: dataset.title}
    data[:question] = create_dataset_question_hash(question, can_exclude, private_user_id)
    data[:broken_down_by] = create_dataset_question_hash(broken_down_by, can_exclude, private_user_id) if broken_down_by.present?
    data[:filtered_by] = create_dataset_question_hash(filtered_by, can_exclude, private_user_id) if filtered_by.present?
    data[:analysis_type] = nil
    data[:results] = nil

    ########################
    # do the analysis
    # if there is no broken down by then do single analysis, else do comparative analysis
    # use the data[] for the parameter values to get answers that should be included in analysis
    if broken_down_by.present?
      data[:analysis_type] = ANALYSIS_TYPE[:comparative]
      data[:results] = dataset_comparative_analysis(dataset, data[:question], data[:broken_down_by], data[:filtered_by], with_title)
      data[:chart] = dataset_comparative_chart(data, with_title, options) if with_chart_data
      data[:map] = dataset_comparative_map(question.answers, broken_down_by.answers, data, question.is_mappable?, with_title, options) if with_map_data && (question.is_mappable? || broken_down_by.is_mappable?)
    else
      data[:analysis_type] = ANALYSIS_TYPE[:single]
      data[:results] = dataset_single_analysis(dataset, data[:question], data[:filtered_by], with_title)
      data[:chart] = dataset_single_chart(data, with_title, options) if with_chart_data
      data[:map] = dataset_single_map(question.answers, data, with_title, options) if with_map_data && question.is_mappable?
    end

    return data
  end


  ########################################
  ## TIME SERIES
  ########################################
  # get list of all time series
  def self.time_series_catalog
    TimeSeries.is_public.sorted
  end

  # get details about a time_series
  # parameters:
  #  - time_series_id - id of time_series to get info on (required)
  #  - language - locale of language to get data in (optional)
  def self.time_series(time_series_id, options={})
    if time_series_id.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.missing_required_params') }]}
    end

    # get options
    language = options['language'].present? ? options['language'].downcase : nil

    time_series = TimeSeries.is_public.find(time_series_id)

    if time_series.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_time_series') }]}
    end

    # if language provided, set it
    if language.present? && time_series.languages.include?(language)
      time_series.current_locale = language
    end

    return time_series
  end

  # get codebook for a time_series
  # parameters:
  #  - time_series_id - id of time_series to get codebook for (required)
  #  - language - locale of language to get data in
  def self.time_series_codebook(time_series_id, options={})
    if time_series_id.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.missing_required_params') }]}
    end

    questions = nil

    # get options
    language = options['language'].present? ? options['language'].downcase : nil

    time_series = TimeSeries.is_public.find(time_series_id)

    if time_series.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_time_series') }]}
    end

    # if language provided, set it
    if language.present? && time_series.languages.include?(language)
      time_series.current_locale = language
    end

    questions = time_series.questions.sorted

    return questions
  end

  # analyse the time series for the passed in parameters
  # parameters:
  #  - time_series_id - id of time_series to analyze (required)
  #  - question_code - code of question to analyze (required)
  #  - filtered_by_code - code of question to filter the analysis by (optioanl)
  #  - can_exclude - boolean indicating if the can_exclude answers should by excluded (optional, default false)
  #  - with_title - boolean indicating if results should include title (optional, default false)
  #  - with_chart_data - boolean indicating if results should include data formatted for highcharts (optional, default false)
  #  - language - locale of language to get data in (optional)
  # return format:
  # {
  #   time_series: {id, title},
  #   datasets: [{id, title, label}, ...],
  #   question: {code, original_code, text, answers: [{value, text, can_exclude}]},
  #   filtered_by: {code, original_code, text, answers: [{value, text, can_exclude}]} (optional),
  #   analysis_type: time_series (will always be time_series)
  #   results: {title, total_responses, analysis: [{dataset_label, answer_text, count, percent}, ...]}
  #   chart: {title, data: [{y(percent), count}, ...] } (optional)
  #   errors: [{status, detail}] (optional)
  # }
  def self.time_series_analysis(time_series_id, question_code, options={})
    data = {}

    if time_series_id.nil? || question_code.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.missing_required_params') }]}
    end


    ########################
    # get options
    private_user_id = options['private_user_id'].present? ? options['private_user_id'] : nil
    can_exclude = options['can_exclude'].present? && options['can_exclude'].to_bool == true
    with_title = options['with_title'].present? && options['with_title'].to_bool == true
    with_chart_data = options['with_chart_data'].present? && options['with_chart_data'].to_bool == true
    language = options['language'].present? ? options['language'].downcase : nil

    time_series = nil
    if private_user_id
      # decode the id
      begin
        user_id = Base64.urlsafe_decode64(private_user_id)
      end
      # get time series
      time_series = TimeSeries.by_id_for_owner(time_series_id, user_id, user_id) if user_id.present?
    else
      time_series = TimeSeries.is_public.find(time_series_id)
    end

    # if the time_series could not be found, stop
    if time_series.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_time_series') }]}
    end

    # if language provided, set it
    if language.present? && time_series.languages.include?(language)
      time_series.current_locale = language
    end

    question = time_series.questions.with_code(question_code)

    # if the question could not be found, stop
    if question.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_question') }]}
    end

    datasets = time_series.datasets.sorted
    dataset_questions = time_series.questions.dataset_questions_in_code(question_code)

    # if the time series has no datasets, stop
    if datasets.nil? || dataset_questions.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_time_series_datasets') }]}
    end


    # if filter by by exists, get it
    filtered_by = nil
    if options['filtered_by_code'].present?
      filtered_by = time_series.questions.with_code(options['filtered_by_code'].strip)

      # if the filter by question could not be found, stop
      if filtered_by.nil?
        return {errors: [{status: '404', detail: I18n.t('api.msgs.no_filtered_by') }]}
      end
    end

    ########################
    # start populating the output
    data[:time_series] = {id: time_series.id, title: time_series.title}
    data[:datasets] = create_time_series_dataset_hash(datasets)
    data[:question] = create_time_series_question_hash(question, can_exclude)
    data[:filtered_by] = create_time_series_question_hash(filtered_by, can_exclude) if filtered_by.present?
    data[:analysis_type] = ANALYSIS_TYPE[:time_series]
    data[:results] = nil

    ########################
    # do the analysis
    # run the analysis for each dataset
    individual_results = []
    dataset_questions.each do |dq|
      x = dataset_analysis(dq.dataset_id, question_code, options)
      if x.present?
        individual_results << {dataset_id: dq.dataset_id, dataset_results:x}
      end
    end

    # if the individual results were not all found,
    if !(individual_results.present? && individual_results.select{|x| x[:errors].nil?}.present?)
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_time_series_dataset_error') }]}
    end

Rails.logger.debug "================ind results has #{individual_results.length} records; id class = #{individual_results.first[:dataset_id].class}"

    data[:results] = time_series_single_analysis(data[:datasets], individual_results, data[:question], data[:filtered_by], with_title)
    data[:chart] = time_series_single_chart(data, with_title, options) if with_chart_data

    return data
  end


  ################################################################################
  ################################################################################
  ################################################################################
  ################################################################################
private

  # only keep the options that are desired
  def self.clean_options(options)
    if options.class == Hash
      # list of keys to keep
      to_keep = %w(dataset_id time_series_id question_code broken_down_by_code filtered_by_code can_exclude with_title with_chart_data with_map_data language filtered_by_value visual_type broken_down_value filtered_by_value)

      # remove any keys that are not in the list
      options = options.dup.delete_if{|k,v| !to_keep.include?(k.to_s)}
    end

    return options
  end


  # create question hash for a dataset
  def self.create_dataset_question_hash(question, can_exclude=false, private_user_id=nil)
    hash = {}
    if question.present?
      hash = {code: question.code, original_code: question.original_code, text: question.text, notes: question.notes, is_mappable: question.is_mappable, has_map_adjustable_max_range: question.has_map_adjustable_max_range}
      # if this question belongs to a group, add it
      if question.group_id.present?
        group = question.group
        if group.present?
          # see if this is a subgroup
          if group.parent_id.present?
            hash[:group] = {title: group.parent.title, description: group.parent.description, include_in_charts: group.parent.include_in_charts}
            hash[:subgroup] = {title: group.title, description: group.description, include_in_charts: group.include_in_charts}
          else
            hash[:group] = {title: group.title, description: group.description, include_in_charts: group.include_in_charts}
          end
        end
      end
      # if this is for admin, include whether the question is excluded
      if private_user_id.present?
        hash[:exclude] = question.exclude
        hash[:answers] = (can_exclude == true ? question.answers.must_include_for_analysis : question.answers.sorted).map{|x| {value: x.value, text: x.text, exclude: x.exclude, can_exclude: x.can_exclude, sort_order: x.sort_order}}
      else
        hash[:answers] = (can_exclude == true ? question.answers.must_include_for_analysis : question.answers.all_for_analysis).map{|x| {value: x.value, text: x.text, can_exclude: x.can_exclude, sort_order: x.sort_order}}
      end
    end

    return hash
  end



  # for the given dataset and question, do a single analysis
  def self.dataset_single_analysis(dataset, question, filtered_by=nil, with_title=false)
    # get the data for this code
    data = dataset.data_items.code_data(question[:code])

    # only keep the data that is in the list of question answers
    # - this is where can_exclude removes the unwanted answers
    answer_values = question[:answers].map{|x| x[:value]}
    data.delete_if{|x| !answer_values.include?(x)}

    # if filter provided, then get data for filter
    # and then only pull out the code data that matches
    if filtered_by.present?
      filter_data = dataset.data_items.code_data(filtered_by[:code]) if filtered_by.present?
      if filter_data.present?
        # merge the data and filter
        # and then pull out the data that has the corresponding filter value
        merged_data = filter_data.zip(data)

        filter_results = nil
        if with_title
          filter_results = {title: {html: nil, text: nil}, subtitle: {html: nil, text: nil}, filter_analysis: []}

          filter_results[:title][:html] = dataset_single_analysis_title('html', question, filtered_by)
          filter_results[:title][:text] = dataset_single_analysis_title('text', question, filtered_by)
        else
          filter_results = {filter_analysis: []}
        end

        filtered_by[:answers].each do |filter_answer|
          filter_item = {filter_answer_value: filter_answer[:value], filter_answer_text: filter_answer[:text]}

          filter_item[:filter_results] = dataset_single_analysis_processing(question, data.length, merged_data.select{|x| x[0].to_s == filter_answer[:value].to_s}.map{|x| x[1]}, with_title, filtered_by, filter_answer[:text])

          filter_results[:filter_analysis] << filter_item
        end

        if with_title
          # needed to run all anaylsis in order to have all total responses for subtitle
          filter_results[:subtitle][:html] = dataset_analysis_subtitle_filtered('html', filtered_by[:original_code], filtered_by[:text], filter_results[:filter_analysis])
          filter_results[:subtitle][:text] = dataset_analysis_subtitle_filtered('text', filtered_by[:original_code], filtered_by[:text], filter_results[:filter_analysis])
        end

        return filter_results
      end
    else
      return dataset_single_analysis_processing(question, data.length, data, with_title)
    end

  end



  # for the given question and it's data, do a single analysis and convert into counts and percents
  def self.dataset_single_analysis_processing(question, total_possible_responses, data, with_title=false, filtered_by=nil, filtered_by_answer=nil)
    results = nil
    if with_title
      results = {title: {html: nil, text: nil}, subtitle: {html: nil, text: nil}, total_responses: 0, total_possible_responses: total_possible_responses, analysis: []}
    else
      results = {total_responses: 0, total_possible_responses: total_possible_responses, analysis: []}
    end

    if data.present?
      # do not want to count nil values
      counts_per_answer = data.select{|x| x.present?}
                            .each_with_object(Hash.new(0)) { |item,counts| counts[item.to_s] += 1 }


      if counts_per_answer.present?
        # record the total response
        results[:total_responses] = counts_per_answer.values.inject(:+)

        # set the titles
        if with_title
          results[:title][:html] = dataset_single_analysis_title('html', question, filtered_by, filtered_by_answer)
          results[:title][:text] = dataset_single_analysis_title('text', question, filtered_by, filtered_by_answer)
          results[:subtitle][:html] = dataset_analysis_subtitle('html', results[:total_responses], results[:total_possible_responses])
          results[:subtitle][:text] = dataset_analysis_subtitle('text', results[:total_responses], results[:total_possible_responses])
        end

        # for each question answer, add the count and percent
        question[:answers].each do |answer|
          value = answer[:value]
          item = {answer_value: answer[:value], answer_text: answer[:text], count: 0, percent: 0}
          if counts_per_answer[value].present?
            item[:count] = counts_per_answer[value]
            item[:percent] = (counts_per_answer[value].to_f/results[:total_responses]*100).round(2) if results[:total_responses] > 0
          end
          results[:analysis] << item
        end
      end
    end
    return results
  end

  # convert the results into pie chart format
  # options are needed to create embed id
  # return format:
  # - no filter: {:data => [ {name, y(percent), count, answer_value}, ...] }
  # - with filter: [ {filter_answer_value, filter_answer_text, filter_results => [ {:data => [ {name, y(percent), count, answer_value}, ...] } ] } ]
  def self.dataset_single_chart(data, with_title=false, options={})
    if data.present?
      chart = nil
      if data[:filtered_by].present?
        chart = []
        data[:results][:filter_analysis].each do |filter|
          chart_item = {filter_answer_value: filter[:filter_answer_value], filter_answer_text: filter[:filter_answer_text], filter_results: {} }

          # set the titles
          # - assume titles are already set in data[:filtered_by][:results]
          if with_title
            chart_item[:filter_results][:title] = filter[:filter_results][:title]
            chart_item[:filter_results][:subtitle] = filter[:filter_results][:subtitle]
          end

          # create embed id
          # add filter value
          options['filtered_by_value'] = filter[:filter_answer_value]
          options['visual_type'] = 'chart'
          chart_item[:filter_results][:embed_id] = Base64.urlsafe_encode64(clean_options(options).to_query)

          # create data for chart
          chart_item[:filter_results][:data] = []
          data[:question][:answers].each do |answer|
            data_result = filter[:filter_results][:analysis].select{|x| x[:answer_value] == answer[:value]}.first
            if data_result.present?
              chart_item[:filter_results][:data] << dataset_single_chart_processing(answer, data_result)
            end
          end
          if chart_item[:filter_results][:data].present?
            chart << chart_item
          end
        end
      else
        chart = {}

        # set the titles
        # - assume titles are already set in data[:results]
        if with_title
          chart[:title] = data[:results][:title]
          chart[:subtitle] = data[:results][:subtitle]
        end

        # create embed id
        options['visual_type'] = 'chart'
        chart[:embed_id] = Base64.urlsafe_encode64(clean_options(options).to_query)

        # create data for chart
        chart[:data] = []
        data[:question][:answers].each do |answer|
          data_result = data[:results][:analysis].select{|x| x[:answer_value] == answer[:value]}.first
          if data_result.present?
            chart[:data] << dataset_single_chart_processing(answer, data_result)
          end
        end
      end

      return chart
    end
  end


  # format: {name, y(percent), count, answer_value}
  def self.dataset_single_chart_processing(answer, data_result)
    {
      name: answer[:text],
      y: data_result[:percent],
      count: data_result[:count],
      answer_value: answer[:value]
    }
  end

  # convert the results into highmaps map format
  # options are needed to create embed id
  # return format:
  # - no filter: {shape_question_code, map_sets => {title, subtitle, data => [ {shape_name, display_name, value, count}, ... ] } }
  # - with filter: [{filter_answer_value, filter_answer_text, shape_question_code, filter_results => [ map_sets => {title, subtitle, data => [ {shape_name, display_name, value, count}, ... ] } ] } ]
  def self.dataset_single_map(answers, data, with_title=false, options={})
    if answers.present? && data.present?
      map = nil

      if data[:filtered_by].present?
        map = []
        data[:results][:filter_analysis].each do |filter|
          map_item = {filter_answer_value: filter[:filter_answer_value], filter_answer_text: filter[:filter_answer_text],
                    filter_results: {shape_question_code: data[:question][:code], adjustable_max_range: data[:question][:has_map_adjustable_max_range], map_sets: {}}}

          # set the titles
          # - assume titles are already set in data[:results]
          if with_title
            map_item[:filter_results][:map_sets][:title] = filter[:filter_results][:title]
            map_item[:filter_results][:map_sets][:subtitle] = filter[:filter_results][:subtitle]
          end

          # create embed id
          # add filter value
          options['filtered_by_value'] = filter[:filter_answer_value]
          options['visual_type'] = 'map'
          map_item[:filter_results][:map_sets][:embed_id] = Base64.urlsafe_encode64(clean_options(options).to_query)

          map_item[:filter_results][:map_sets][:data] = []
          answers.each_with_index do |answer|
            data_result = filter[:filter_results][:analysis].select{|x| x[:answer_value] == answer.value}.first
            if data_result.present?
              map_item[:filter_results][:map_sets][:data] << dataset_single_map_processing(answer, data_result)
            end
          end

          if map_item[:filter_results][:map_sets][:data].present?
            map << map_item
          end
        end

      else
        # need question code so know which shape data to use
        map = {shape_question_code: data[:question][:code], adjustable_max_range: data[:question][:has_map_adjustable_max_range], map_sets: {}}

        # set the titles
        # - assume titles are already set in data[:results]
        if with_title
          map[:map_sets][:title] = data[:results][:title]
          map[:map_sets][:subtitle] = data[:results][:subtitle]
        end

        # create embed id
        options['visual_type'] = 'map'
        map[:map_sets][:embed_id] = Base64.urlsafe_encode64(clean_options(options).to_query)

        # load the data
        map[:map_sets][:data] = []
        answers.each_with_index do |answer|
          data_result = data[:results][:analysis].select{|x| x[:answer_value] == answer.value}.first
          if data_result.present?
            map[:map_sets][:data] << dataset_single_map_processing(answer, data_result)
          end
        end
      end

      return map
    end
  end

  # format: {shape_name, display_name, value, count}
  def self.dataset_single_map_processing(answer, data_result)
    {
      :shape_name => answer.shape_name,
      :display_name => answer.text,
      :value => data_result[:percent],
      :count => data_result[:count]
    }
  end

  #######################################3

  # for the given dataset, question and broken down by question, do a comparative analysis
  def self.dataset_comparative_analysis(dataset, question, broken_down_by, filtered_by=nil, with_title=false)
    # get the values for the codes from the data
    question_data = dataset.data_items.code_data(question[:code])
    broken_down_data = dataset.data_items.code_data(broken_down_by[:code])

    # merge the data arrays into one array that
    # has nested arrays
    data = question_data.zip(broken_down_data)

    # only keep the data that is in the list of question/broken down by answers
    # - this is where can_exclude removes the unwanted answers
    q_answer_values = question[:answers].map{|x| x[:value]}
    bdb_answer_values = broken_down_by[:answers].map{|x| x[:value]}
    data.delete_if{|x| !q_answer_values.include?(x[0]) && !bdb_answer_values.include?(x[1])}

    # if filter provided, then get data for filter
    # and then only pull out the code data that matches
    if filtered_by.present?
      filter_data = dataset.data_items.code_data(filtered_by[:code]) if filtered_by.present?
      if filter_data.present?
        # merge the data and filter
        # and then pull out the data that has the corresponding filter value
        merged_data = filter_data.zip(data)
        filter_results = nil
        if with_title
          filter_results = {title: {html: nil, text: nil}, subtitle: {html: nil, text: nil}, filter_analysis: []}

          filter_results[:title][:html] = dataset_comparative_analysis_title('html', question, broken_down_by, filtered_by)
          filter_results[:title][:text] = dataset_comparative_analysis_title('text', question, broken_down_by, filtered_by)
        else
          filter_results = {filter_analysis: []}
        end

        filtered_by[:answers].each do |filter_answer|
          filter_item = {filter_answer_value: filter_answer[:value], filter_answer_text: filter_answer[:text]}

          filter_item[:filter_results] = dataset_comparative_analysis_processing(question, broken_down_by, data.length, merged_data.select{|x| x[0].to_s == filter_answer[:value].to_s}.map{|x| x[1]}, with_title, filtered_by, filter_answer[:text])

          filter_results[:filter_analysis] << filter_item
        end

        if with_title
          # needed to run all anaylsis in order to have all total responses for subtitle
          filter_results[:subtitle][:html] = dataset_analysis_subtitle_filtered('html', filtered_by[:original_code], filtered_by[:text], filter_results[:filter_analysis])
          filter_results[:subtitle][:text] = dataset_analysis_subtitle_filtered('text', filtered_by[:original_code], filtered_by[:text], filter_results[:filter_analysis])
        end

        return filter_results
      end
    else
      return dataset_comparative_analysis_processing(question, broken_down_by, data.length, data, with_title)
    end

  end



  # for the given dataset, question and broken down by question, do a comparative analysis and convert into counts and percents
  # data is an array of [question answer, broken down by answer]
  def self.dataset_comparative_analysis_processing(question, broken_down_by, total_possible_responses, data, with_title=false, filtered_by=nil, filtered_by_answer=nil)
    results = nil
    if with_title
      results = {title: {html: nil, text: nil}, subtitle: {html: nil, text: nil}, total_responses: 0, total_possible_responses: total_possible_responses, analysis: []}
    else
      results = {total_responses: 0, total_possible_responses: total_possible_responses, analysis: []}
    end
    question_answer_template = {answer_value: nil, answer_text: nil, broken_down_results: nil}
    broken_down_answer_template = {broken_down_answer_value: nil, broken_down_answer_text: nil, count: 0, percent: 0}

    if data.present?
      # get the counts for each question answer by each broken down answer
      # format: {question_answer: [{broken_down_answer: count, broken_down_answer: count, broken_down_answer: count, }], ...}
      counts_per_answer = {}
      data.map{|x| x[0]}.uniq.each do |data_item|
        # do not include nil values
        if data_item.present?
          # get the broken down values that exist with this answer
          # and then count how many times each appears
          # do not process nil values for x[1]
          counts_per_answer[data_item.to_s] = data.select{|x| x[0] == data_item && x[1].present?}.map{|x| x[1]}
                                    .each_with_object(Hash.new(0)) { |item,counts| counts[item.to_s] += 1 }
        end
      end

      if counts_per_answer.present?
        # - create counts and percents
        total = 0
        question[:answers].each do |answer|
          answer_counts = counts_per_answer[answer[:value].to_s]
          question_answer_count = 0
          item = question_answer_template.clone
          item[:answer_value] = answer[:value]
          item[:answer_text] = answer[:text]
          item[:broken_down_results] = []

          broken_down_by[:answers].each do |bdb_answer|
            bdb_item = broken_down_answer_template.clone
            bdb_item[:broken_down_answer_value] = bdb_answer[:value]
            bdb_item[:broken_down_answer_text] = bdb_answer[:text]

            if answer_counts.present? && answer_counts[bdb_answer[:value].to_s].present?
              bdb_item[:count] = answer_counts[bdb_answer[:value].to_s]
              question_answer_count += answer_counts[bdb_answer[:value].to_s]
            end

            item[:broken_down_results] << bdb_item
          end

          if question_answer_count > 0
            # now that the coutns for the question answer is done, compute the percents
            item[:broken_down_results].each do |bdr_item|
              bdr_item[:percent] = (bdr_item[:count].to_f/question_answer_count*100).round(2)
            end

            # update overall total
            total += question_answer_count
          end

          results[:analysis] << item
        end

        # total responses
        results[:total_responses] = total

        # set the titles
        if with_title
          results[:title][:html] = dataset_comparative_analysis_title('html', question, broken_down_by, filtered_by, filtered_by_answer)
          results[:title][:text] = dataset_comparative_analysis_title('text', question, broken_down_by, filtered_by, filtered_by_answer)
          results[:subtitle][:html] = dataset_analysis_subtitle('html', results[:total_responses], results[:total_possible_responses])
          results[:subtitle][:text] = dataset_analysis_subtitle('text', results[:total_responses], results[:total_possible_responses])
        end
      end

    end
    return results
  end


  # convert the results into stacked bar chart format
  # options are needed to create embed id
  # return format:
  # - no filter: {:data => [ {name, y(percent), count, answer_value}, ...] }
  # - with filter: [ {filter_answer_value, filter_results => [ {:data => [ {name, y(percent), count, answer_value}, ...] } ] } ]
  def self.dataset_comparative_chart(data, with_title=false, options={})
    if data.present?
      chart = nil
      if data[:filtered_by].present?
        chart = []
        data[:results][:filter_analysis].each do |filter|
          chart_item = {filter_answer_value: filter[:filter_answer_value], filter_answer_text: filter[:filter_answer_text], filter_results: {}}

          # set the titles
          # - assume titles are already set in data[:filtered_by][:results]
          if with_title
            chart_item[:filter_results][:title] = filter[:filter_results][:title]
            chart_item[:filter_results][:subtitle] = filter[:filter_results][:subtitle]
          end

          # create embed id
          # add filter value
          options['filtered_by_value'] = filter[:filter_answer_value]
          options['visual_type'] = 'chart'
          chart_item[:filter_results][:embed_id] = Base64.urlsafe_encode64(clean_options(options).to_query)

          chart_item[:filter_results][:labels] = data[:question][:answers].map{|x| x[:text]}

          # have to transpose the counts for highcharts
          counts = filter[:filter_results][:analysis].map{|x| x[:broken_down_results].map{|y| y[:count]}}.transpose
          if counts.present?
            chart_item[:filter_results][:data] = []
            data[:broken_down_by][:answers].each_with_index do |answer, i|
              chart_item[:filter_results][:data] << {name: answer[:text], data: counts[i]}
            end

            chart << chart_item
          end
        end
      else
        chart = {}

        # set the titles
        # - assume titles are already set in data[:results]
        if with_title
          chart[:title] = data[:results][:title]
          chart[:subtitle] = data[:results][:subtitle]
        end

        # create embed id
        options['visual_type'] = 'chart'
        chart[:embed_id] = Base64.urlsafe_encode64(clean_options(options).to_query)

        chart[:labels] = data[:question][:answers].map{|x| x[:text]}

        chart[:data] = []
        # have to transpose the counts for highcharts
        counts = data[:results][:analysis].map{|x| x[:broken_down_results].map{|y| y[:count]}}.transpose

        data[:broken_down_by][:answers].each_with_index do |answer, i|
          chart[:data] << {name: answer[:text], data: counts[i]}
        end
      end

      return chart
    end
  end


  # convert the results into highmaps map format
  # options are needed to create embed id
  # return format:
  # - no filter: {shape_question_code, map_sets => [{title, subtitle, data => [ {shape_name, display_name, value, count}, ... ] } ] }
  # - with filter: [{filter_answer_value, filter_answer_text, shape_question_code, filter_results => [ map_sets => [{title, subtitle, data => [ {shape_name, display_name, value, count}, ... ] } ] } ]
  def self.dataset_comparative_map(question_answers, broken_down_by_answers, data, question_mappable=true, with_title=false, options={})
    if question_answers.present? && broken_down_by_answers.present? && data.present?
      map = nil
      if data[:filtered_by].present?
        map = []
        data[:results][:filter_analysis].each do |filter|
          map_item = {filter_answer_value: filter[:filter_answer_value], filter_answer_text: filter[:filter_answer_text],
                    filter_results: {}}


          if question_mappable
            # need question code so know which shape data to use
            map_item[:filter_results][:shape_question_code] = data[:question][:code]
            map_item[:filter_results][:adjustable_max_range] = data[:question][:has_map_adjustable_max_range]

            # have to transpose the counts for highcharts (and re-calculate percents)
            counts = filter[:filter_results][:analysis].map{|x| x[:broken_down_results].map{|y| y[:count]}}.transpose
            percents = []
            counts.each do |count_row|
              total = count_row.inject(:+)
              if total > 0
                percent_row = []
                count_row.each do |item|
                  percent_row << (item.to_f/total*100).round(2)
                end
                percents << percent_row
              else
                percents << Array.new(count_row.length){0}
              end
            end

            map_item[:filter_results][:map_sets] = []
            broken_down_by_answers.each_with_index do |bdb_answer, bdb_index|
              item = {broken_down_answer_value: bdb_answer.value, broken_down_answer_text: bdb_answer.text}

              # set the titles
              if with_title
                item[:title] = {}
                item[:title][:html] = dataset_comparative_analysis_map_title('html', data[:question], data[:broken_down_by], bdb_answer.text, data[:filtered_by], filter[:filter_answer_text])
                item[:title][:text] = dataset_comparative_analysis_map_title('text', data[:question], data[:broken_down_by], bdb_answer.text, data[:filtered_by], filter[:filter_answer_text])
                item[:subtitle] = {}
                subtitle_count = counts[bdb_index].present? ? counts[bdb_index].inject(:+) : 0
                item[:subtitle][:html] = dataset_analysis_subtitle('html', subtitle_count, filter[:filter_results][:total_possible_responses])
                item[:subtitle][:text] = dataset_analysis_subtitle('text', subtitle_count, filter[:filter_results][:total_possible_responses])
              end

              # create embed id
              # add broken down by value & filter value
              options['broken_down_value'] = bdb_answer.value
              options['filtered_by_value'] = filter[:filter_answer_value]
              options['visual_type'] = 'map'
              item[:embed_id] = Base64.urlsafe_encode64(clean_options(options).to_query)

              # load the data
              item[:data] = []
              if counts.present?
                question_answers.each_with_index do |q_answer, q_index|

                  item[:data] << dataset_comparative_map_processing(q_answer, percents[bdb_index][q_index], counts[bdb_index][q_index])
                end
              end

              map_item[:filter_results][:map_sets] << item
            end
          else
            # need question code so know which shape data to use
            map_item[:filter_results][:shape_question_code] = data[:broken_down_by][:code]
            map_item[:filter_results][:adjustable_max_range] = data[:question][:has_map_adjustable_max_range]

            counts = filter[:filter_results][:analysis].map{|x| x[:broken_down_results].map{|y| y[:count]}}
            percents = filter[:filter_results][:analysis].map{|x| x[:broken_down_results].map{|y| y[:percent]}}

            map_item[:filter_results][:map_sets] = []
            if counts.present?
              question_answers.each_with_index do |q_answer, q_index|
                item = {broken_down_answer_value: q_answer.value, broken_down_answer_text: q_answer.text}

                # set the titles
                if with_title
                  item[:title] = {}
                  item[:title][:html] = dataset_comparative_analysis_map_title('html', data[:broken_down_by], data[:question], q_answer.text, data[:filtered_by], filter[:filter_answer_text])
                  item[:title][:text] = dataset_comparative_analysis_map_title('text', data[:broken_down_by], data[:question], q_answer.text, data[:filtered_by], filter[:filter_answer_text])
                  item[:subtitle] = {}
                  subtitle_count = counts[q_index].present? ? counts[q_index].inject(:+) : 0
                  item[:subtitle][:html] = dataset_analysis_subtitle('html', subtitle_count, filter[:filter_results][:total_possible_responses])
                  item[:subtitle][:text] = dataset_analysis_subtitle('text', subtitle_count, filter[:filter_results][:total_possible_responses])
                end

                # create embed id
                # add broken down by value & filter value
                options['broken_down_value'] = q_answer.value
                options['filtered_by_value'] = filter[:filter_answer_value]
                options['visual_type'] = 'map'
                item[:embed_id] = Base64.urlsafe_encode64(clean_options(options).to_query)

                # load the data
                item[:data] = []
                broken_down_by_answers.each_with_index do |bdb_answer, bdb_index|
                  item[:data] << dataset_comparative_map_processing(bdb_answer, percents[q_index][bdb_index], counts[q_index][bdb_index])
                end
                map_item[:filter_results][:map_sets] << item
              end
            end
          end

          if map_item[:filter_results][:map_sets].present?
            map << map_item
          end
        end

      else

        map = {shape_question_code: nil, map_sets: []}

        if question_mappable
          # need question code so know which shape data to use
          map[:shape_question_code] = data[:question][:code]
          map[:adjustable_max_range] = data[:question][:has_map_adjustable_max_range]

          # have to transpose the counts for highcharts (and re-calculate percents)
          counts = data[:results][:analysis].map{|x| x[:broken_down_results].map{|y| y[:count]}}.transpose
          percents = []
          counts.each do |count_row|
            total = count_row.inject(:+)
            if total > 0
              percent_row = []
              count_row.each do |item|
                percent_row << (item.to_f/total*100).round(2)
              end
              percents << percent_row
            else
              percents << Array.new(count_row.length){0}
            end
          end

          broken_down_by_answers.each_with_index do |bdb_answer, bdb_index|
            item = {broken_down_answer_value: bdb_answer.value, broken_down_answer_text: bdb_answer.text}

            # set the titles
            if with_title
              item[:title] = {}
              item[:title][:html] = dataset_comparative_analysis_map_title('html', data[:question], data[:broken_down_by], bdb_answer.text)
              item[:title][:text] = dataset_comparative_analysis_map_title('text', data[:question], data[:broken_down_by], bdb_answer.text)
              item[:subtitle] = {}
              subtitle_count = counts[bdb_index].present? ? counts[bdb_index].inject(:+) : 0
              item[:subtitle][:html] = dataset_analysis_subtitle('html', subtitle_count, data[:results][:total_possible_responses])
              item[:subtitle][:text] = dataset_analysis_subtitle('text', subtitle_count, data[:results][:total_possible_responses])
            end

            # create embed id
            # add broken down by value
            options['broken_down_value'] = bdb_answer.value
            options['visual_type'] = 'map'
            item[:embed_id] = Base64.urlsafe_encode64(clean_options(options).to_query)

            # load the data
            item[:data] = []
            if counts.present?
              question_answers.each_with_index do |q_answer, q_index|
                item[:data] << dataset_comparative_map_processing(q_answer, percents[bdb_index][q_index], counts[bdb_index][q_index])
              end
            end
            map[:map_sets] << item
          end
        else
          # need question code so know which shape data to use
          map[:shape_question_code] = data[:broken_down_by][:code]
          map[:adjustable_max_range] = data[:question][:has_map_adjustable_max_range]

          counts = data[:results][:analysis].map{|x| x[:broken_down_results].map{|y| y[:count]}}
          percents = data[:results][:analysis].map{|x| x[:broken_down_results].map{|y| y[:percent]}}

          question_answers.each_with_index do |q_answer, q_index|
            item = {broken_down_answer_value: q_answer.value, broken_down_answer_text: q_answer.text}

            # set the titles
            if with_title
              item[:title] = {}
              item[:title][:html] = dataset_comparative_analysis_map_title('html', data[:broken_down_by], data[:question], q_answer.text)
              item[:title][:text] = dataset_comparative_analysis_map_title('text', data[:question], data[:broken_down_by], q_answer.text)
              item[:subtitle] = {}
              subtitle_count = counts[q_index].present? ? counts[q_index].inject(:+) : 0
              item[:subtitle][:html] = dataset_analysis_subtitle('html', subtitle_count, data[:results][:total_possible_responses])
              item[:subtitle][:text] = dataset_analysis_subtitle('text', subtitle_count, data[:results][:total_possible_responses])
            end

            # create embed id
            # add broken down by value
            options['broken_down_value'] = q_answer.value
            options['visual_type'] = 'map'
            item[:embed_id] = Base64.urlsafe_encode64(clean_options(options).to_query)

            # load the data
            item[:data] = []
            broken_down_by_answers.each_with_index do |bdb_answer, bdb_index|
              item[:data] << dataset_comparative_map_processing(bdb_answer, percents[q_index][bdb_index], counts[q_index][bdb_index])
            end
            map[:map_sets] << item
          end
        end
      end

      return map
    end
  end

  # format: {shape_name, display_name, value, count}
  def self.dataset_comparative_map_processing(answer, percent, count)
    {
      :shape_name => answer.shape_name,
      :display_name => answer.text,
      :value => percent,
      :count => count
    }
  end


  ########################################
  ########################################
  ########################################
  ########################################

  # create array of dataset hash for a time series
  def self.create_time_series_dataset_hash(datasets)
    if datasets.present?
      ary = []

      datasets.each do |dataset|
        if dataset.present?
          hash = {dataset_id: dataset.dataset_id, title: dataset.dataset_title, label: dataset.title}
        end
        ary << hash
      end

      return ary
    end
  end


  # create question hash for a time series
  def self.create_time_series_question_hash(question, can_exclude=false)
    hash = {}
    if question.present?
      hash = {code: question.code, original_code: question.original_code, text: question.text, notes: question.notes}
      hash[:answers] = (can_exclude == true ? question.answers.must_include_for_analysis : question.answers.sorted).map{|x| {value: x.value, text: x.text, can_exclude: x.can_exclude, sort_order: x.sort_order}}
    end

    return hash
  end


  # for the given time_series and question, do a single analysis
  def self.time_series_single_analysis(datasets, individual_results, question, filtered_by=nil, with_title=false)
    # if filter provided, then get data for filter
    # and then only pull out the code data that matches
    if filtered_by.present?
      filter_results = nil
      if with_title
        filter_results = {title: {html: nil, text: nil}, subtitle: {html: nil, text: nil}, filter_analysis: []}

        filter_results[:title][:html] = time_series_single_analysis_title_html(question, filtered_by)
        filter_results[:title][:text] = time_series_single_analysis_title_text(question, filtered_by)
      else
        filter_results = {filter_analysis: []}
      end

      filtered_by[:answers].each do |filter_answer|
        filter_item = {filter_answer_value: filter_answer[:value], filter_answer_text: filter_answer[:text]}

        filter_item[:filter_results] = time_series_single_analysis_processing(datasets, individual_results, question, with_title, filtered_by, filter_answer[:value])

        filter_results[:filter_analysis] << filter_item
      end

      if with_title
        # needed to run all anaylsis in order to have all total responses for subtitle
        filter_results[:subtitle][:html] = time_series_analysis_subtitle_html_filtered(filtered_by[:original_code], filtered_by[:text], filter_results[:filter_analysis])
        filter_results[:subtitle][:text] = time_series_analysis_subtitle_text_filtered(filtered_by[:original_code], filtered_by[:text], filter_results[:filter_analysis])
      end

      return filter_results
    else
      return time_series_single_analysis_processing(datasets, individual_results, question, with_title)
    end

  end



  # for the given question and it's data, do a single analysis and convert into counts and percents
  def self.time_series_single_analysis_processing(datasets, individual_results, question, with_title=false, filter_by=nil, filter_answer_value=nil)
    results = nil
    if with_title
      results = {title: {html: nil, text: nil}, subtitle: {html: nil, text: nil}, total_responses: [], analysis: []}
    else
      results = {total_responses: [], analysis: []}
    end

    question[:answers].each do |answer|
      answer_item = {answer_value: answer[:value], answer_text: answer[:text], dataset_results: []}

      datasets.each do |dataset|
        Rails.logger.debug "============== dataset = #{dataset[:label]}; id class = #{dataset[:dataset_id].class}"
        dataset_item = {dataset_label: dataset[:label], dataset_title: dataset[:title], count: 0, percent: 0}

        # see if this dataset had results
        individual_result = individual_results.select{|x| x[:dataset_id].to_s == dataset[:dataset_id].to_s}.first
        if individual_result.present?
          Rails.logger.debug "============== found result"
          # get results from dataset
          dataset_answer_results = nil
          if filter_answer_value.present?
            filter_results = individual_result[:dataset_results][:results][:filter_analysis].select{|x| x[:filter_answer_value] == filter_answer_value}.first
            dataset_answer_results = filter_results[:filter_results][:analysis].select{|x| x[:answer_value] == answer[:value]}.first if filter_results.present?
          else
            dataset_answer_results = individual_result[:dataset_results][:results][:analysis].select{|x| x[:answer_value] == answer[:value]}.first
          end
          Rails.logger.debug "============== answer results = #{dataset_answer_results}"

          if dataset_answer_results.present?
            dataset_item[:count] = dataset_answer_results[:count]
            dataset_item[:percent] = dataset_answer_results[:percent]
          end
        end
        answer_item[:dataset_results] << dataset_item
      end

      results[:analysis] << answer_item
    end


    # add total responses for each dataset
    datasets.each do |dataset|
      response_item = {dataset_label: dataset[:label], dataset_title: dataset[:title], count: 0}

      # see if this dataset had results
      individual_result = individual_results.select{|x| x[:dataset_id].to_s == dataset[:dataset_id].to_s}.first
      if individual_result.present?
        if filter_answer_value.present?
          filter_results = individual_result[:dataset_results][:results][:filter_analysis].select{|x| x[:filter_answer_value] == filter_answer_value}.first
          response_item[:count] = filter_results[:filter_results][:total_responses] if filter_results.present?
        else
          response_item[:count] = individual_result[:dataset_results][:results][:total_responses]
        end
      end

      results[:total_responses] << response_item
    end

    # set the titles
    if with_title
      if filter_answer_value.present?
        # look for any match in filter results with the filter answer value
        filter_result = individual_results.map{|x| x[:dataset_results][:results][:filter_analysis]}.flatten.select{|x| x[:filter_answer_value] == filter_answer_value}.first
        if filter_result.present?
          results[:title][:html] = time_series_single_analysis_title_html(question, filter_by, filter_result[:filter_answer_text])
          results[:title][:text] = time_series_single_analysis_title_text(question, filter_by, filter_result[:filter_answer_text])
          results[:subtitle][:html] = time_series_analysis_subtitle_html(results[:total_responses])
          results[:subtitle][:text] = time_series_analysis_subtitle_text(results[:total_responses])
        end
      else
        results[:title][:html] = time_series_single_analysis_title_html(question)
        results[:title][:text] = time_series_single_analysis_title_text(question)
        results[:subtitle][:html] = time_series_analysis_subtitle_html(results[:total_responses])
        results[:subtitle][:text] = time_series_analysis_subtitle_text(results[:total_responses])
      end
    end

    return results
  end


  # convert the results into pie chart format
  # options are needed to create embed id
  # return format:
  # - no filter: {title, subtitle, datasets, data => [ {name, y(percent), count, answer_value}, ...] }
  # - with filter: [ {filter_answer_value, filter_answer_text, filter_results => [ {title, subtitle, datasets, data => [ {name, y(percent), count, answer_value}, ...] } ] } ]
  def self.time_series_single_chart(data, with_title=false, options={})
    if data.present?
      chart = nil
      datasets = data[:datasets].map{|x| x[:label]}

      if data[:filtered_by].present?
        chart = []
        data[:results][:filter_analysis].each do |filter|
          chart_item = {filter_answer_value: filter[:filter_answer_value], filter_answer_text: filter[:filter_answer_text], filter_results: {}}

          # set the titles
          # - assume titles are already set in data[:filtered_by][:results]
          if with_title
            chart_item[:filter_results][:title] = filter[:filter_results][:title]
            chart_item[:filter_results][:subtitle] = filter[:filter_results][:subtitle]
          end

          chart_item[:filter_results][:datasets] = datasets

          # create embed id
          # add filter value
          options['filtered_by_value'] = filter[:filter_answer_value]
          options['visual_type'] = 'chart'
          chart_item[:filter_results][:embed_id] = Base64.urlsafe_encode64(clean_options(options).to_query)


          chart_item[:filter_results][:data] = []
          data[:question][:answers].each do |answer|
            result_item = {name: answer[:text], data:[]}

            data_result = filter[:filter_results][:analysis].select{|x| x[:answer_value] == answer[:value]}.first
            if data_result.present?
              data_result[:dataset_results].each do |dataset_result|
                result_item[:data] << time_series_single_chart_processing(dataset_result)
              end
            end
            chart_item[:filter_results][:data] << result_item
          end
          if chart_item[:filter_results][:data].present?
            chart << chart_item
          end
        end
      else
        chart = {}

        # set the titles
        # - assume titles are already set in data[:results]
        if with_title
          chart[:title] = data[:results][:title]
          chart[:subtitle] = data[:results][:subtitle]
        end

        chart[:datasets] = datasets

        # create embed id
        options['visual_type'] = 'chart'
        chart[:embed_id] = Base64.urlsafe_encode64(clean_options(options).to_query)

        chart[:data] = []
        data[:question][:answers].each do |answer|
          chart_item = {name: answer[:text], data:[]}

          data_result = data[:results][:analysis].select{|x| x[:answer_value] == answer[:value]}.first
          if data_result.present?
            data_result[:dataset_results].each do |dataset_result|
              chart_item[:data] << time_series_single_chart_processing(dataset_result)
            end
          end

          chart[:data] << chart_item
        end
      end

      return chart
    end
  end


  # format: {y(percent), count}
  def self.time_series_single_chart_processing(data_result)
    {
      y: data_result[:percent],
      count: data_result[:count]
    }
  end


  ########################################
  ########################################
  ########################################
  ########################################


  def self.dataset_single_analysis_title(locale_key, question, filtered_by=nil, filtered_by_answer=nil)
    group = ''
    if question[:group].present? && question[:group][:include_in_charts]
      group << I18n.t('explore_data.v1.title_group', text: question[:group][:description])
      if question[:subgroup].present? && question[:subgroup][:include_in_charts]
        group << I18n.t('explore_data.v1.title_subgroup', text: question[:subgroup][:description])
      end
    end
    title = I18n.t("explore_data.single.#{locale_key}.title", :code => question[:original_code], :variable => question[:text], :group => group)
    if filtered_by.present?
      group = ''
      if filtered_by[:group].present? && filtered_by[:group][:include_in_charts]
        group << I18n.t('explore_data.v1.title_group', text: filtered_by[:group][:description])
        if filtered_by[:subgroup].present? && filtered_by[:subgroup][:include_in_charts]
          group << I18n.t('explore_data.v1.title_subgroup', text: filtered_by[:subgroup][:description])
        end
      end
      if filtered_by_answer.present?
        title << I18n.t("explore_data.single.#{locale_key}.title_filter_value", :code => filtered_by[:original_code], :variable => filtered_by[:text], :value => filtered_by_answer, :group => group )
      else
        title << I18n.t("explore_data.single.#{locale_key}.title_filter", :code => filtered_by[:original_code], :variable => filtered_by[:text], :group => group)
      end
    end
    return title.html_safe
  end

  def self.dataset_comparative_analysis_title(locale_key, question, broken_down_by, filtered_by=nil, filtered_by_answer=nil)
    group = ''
    if question[:group].present? && question[:group][:include_in_charts]
      group << I18n.t('explore_data.v1.title_group', text: question[:group][:description])
      if question[:subgroup].present? && question[:subgroup][:include_in_charts]
        group << I18n.t('explore_data.v1.title_subgroup', text: question[:subgroup][:description])
      end
    end
    group2 = ''
    if broken_down_by[:group].present? && broken_down_by[:group][:include_in_charts]
      group2 << I18n.t('explore_data.v1.title_group', text: broken_down_by[:group][:description])
      if broken_down_by[:subgroup].present? && broken_down_by[:subgroup][:include_in_charts]
        group2 << I18n.t('explore_data.v1.title_subgroup', text: broken_down_by[:subgroup][:description])
      end
    end
    title = I18n.t("explore_data.comparative.#{locale_key}.title", :question_code => question[:original_code], :variable => question[:text],
              :broken_down_by_code => broken_down_by[:original_code], :broken_down_by => broken_down_by[:text], :group => group, :group2 => group2)
    if filtered_by.present?
      group = ''
      if filtered_by[:group].present? && filtered_by[:group][:include_in_charts]
        group << I18n.t('explore_data.v1.title_group', text: filtered_by[:group][:description])
        if filtered_by[:subgroup].present? && filtered_by[:subgroup][:include_in_charts]
          group << I18n.t('explore_data.v1.title_subgroup', text: filtered_by[:subgroup][:description])
        end
      end
      if filtered_by_answer.present?
        title << I18n.t("explore_data.comparative.#{locale_key}.title_filter_value", :code => filtered_by[:original_code], :variable => filtered_by[:text], :value => filtered_by_answer, :group => group )
      else
        title << I18n.t("explore_data.comparative.#{locale_key}.title_filter", :code => filtered_by[:original_code], :variable => filtered_by[:text], :group => group )
      end
    end
    return title.html_safe
  end

  def self.dataset_comparative_analysis_map_title(locale_key, question, broken_down_by, broken_down_by_answer, filtered_by=nil, filtered_by_answer=nil)
    group = ''
    if question[:group].present? && question[:group][:include_in_charts]
      group << I18n.t('explore_data.v1.title_group', text: question[:group][:description])
      if question[:subgroup].present? && question[:subgroup][:include_in_charts]
        group << I18n.t('explore_data.v1.title_subgroup', text: question[:subgroup][:description])
      end
    end
    group2 = ''
    if broken_down_by[:group].present? && broken_down_by[:group][:include_in_charts]
      group2 << I18n.t('explore_data.v1.title_group', text: broken_down_by[:group][:description])
      if broken_down_by[:subgroup].present? && broken_down_by[:subgroup][:include_in_charts]
        group2 << I18n.t('explore_data.v1.title_subgroup', text: broken_down_by[:subgroup][:description])
      end
    end
    title = I18n.t("explore_data.comparative.#{locale_key}.map.title", :code => question[:original_code], :variable => question[:text], :group => group)
    title << I18n.t("explore_data.comparative.#{locale_key}.map.title_broken_down_by", :code => broken_down_by[:original_code], :broken_down_by => broken_down_by[:text], :broken_down_by_answer => broken_down_by_answer, :group => group2)
    if filtered_by.present?
      group = ''
      if filtered_by[:group].present? && filtered_by[:group][:include_in_charts]
        group << I18n.t('explore_data.v1.title_group', text: filtered_by[:group][:description])
        if filtered_by[:subgroup].present? && filtered_by[:subgroup][:include_in_charts]
          group << I18n.t('explore_data.v1.title_subgroup', text: filtered_by[:subgroup][:description])
        end
      end
      if filtered_by_answer.present?
        title << I18n.t("explore_data.comparative.#{locale_key}.map.title_filter_value", :code => filtered_by[:original_code], :variable => filtered_by[:text], :value => filtered_by_answer, :group => group )
      else
        title << I18n.t("explore_data.comparative.#{locale_key}.map.title_filter", :code => filtered_by[:original_code], :variable => filtered_by[:text], :group => group )
      end
    end
    return title.html_safe
  end


  def self.dataset_analysis_subtitle(locale_key, num, total)
      title = ''
      if locale_key == 'html'
        title << "<br /> <span class='total_responses'>"
      end
      title << I18n.t("explore_data.subtitle.#{locale_key}.title", :num => number_with_delimiter(num), total: number_with_delimiter(total))
      if locale_key == 'html'
        title << "</span>"
      end
      return title.html_safe
  end

  def self.dataset_analysis_subtitle_filtered(locale_key, filtered_by_code, filtered_by_text, results)
    title = ''
    join_text = locale_key == 'html' ? '' : '; '
    if locale_key == 'html'
      title = "<br /> <span class='total_responses'>"
    end
    filter_responses = []
    results.each do |result|
      if locale_key == 'html'
        filter_responses << "<br /> - #{result[:filter_answer_text]}: <span class='number'>#{number_with_delimiter(result[:filter_results][:total_responses])}</span>"
      else
        filter_responses << " #{result[:filter_answer_text]}: #{number_with_delimiter(result[:filter_results][:total_responses])}"
      end
    end
    title << I18n.t("explore_data.subtitle.#{locale_key}.title_filter", :code => filtered_by_code, :variable => filtered_by_text, :nums => filter_responses.join(join_text))
    if locale_key == 'html'
      title << "</span>"
    end
    return title.html_safe
  end





  def self.time_series_single_analysis_title_html(question, filtered_by=nil, filtered_by_answer=nil)
    title = I18n.t('explore_time_series.v1.single.html.title', :code => question[:original_code], :variable => question[:text])
    if filtered_by.present?
      if filtered_by_answer.present?
        title << I18n.t('explore_time_series.v1.single.html.title_filter_value', :code => filtered_by[:original_code], :variable => filtered_by[:text], :value => filtered_by_answer )
      else
        title << I18n.t('explore_time_series.v1.single.html.title_filter', :code => filtered_by[:original_code], :variable => filtered_by[:text] )
      end
    end
    return title.html_safe
  end

  def self.time_series_single_analysis_title_text(question, filtered_by=nil, filtered_by_answer=nil)
    title = I18n.t('explore_time_series.v1.single.text.title', :code => question[:original_code], :variable => question[:text])
    if filtered_by.present?
      if filtered_by_answer.present?
        title << I18n.t('explore_time_series.v1.single.text.title_filter_value', :code => filtered_by[:original_code], :variable => filtered_by[:text], :value => filtered_by_answer )
      else
        title << I18n.t('explore_time_series.v1.single.text.title_filter', :code => filtered_by[:original_code], :variable => filtered_by[:text] )
      end
    end
    return title
  end

  def self.time_series_analysis_subtitle_html(totals)
    title = "<br /> <span class='total_responses'>"
    num = []
    totals.each do |total|
      num << "#{total[:dataset_label]}: <span class='number'>#{number_with_delimiter(total[:count])}</span>"
    end
    title << I18n.t('explore_time_series.v1.subtitle.html.title', :num => num.join('; '))
    title << "</span>"
    return title.html_safe
  end

  def self.time_series_analysis_subtitle_text(totals)
    num = []
    totals.each do |total|
      num << "#{total[:dataset_label]}: #{number_with_delimiter(total[:count])}"
    end
    return I18n.t('explore_time_series.v1.subtitle.text.title', :num => num.join('; '))
  end

  def self.time_series_analysis_subtitle_html_filtered(filtered_by_code, filtered_by_text, results)
    title = "<br /> <span class='total_responses'>"
    filter_responses = []
    results.each do |result|
      text = "<br /> - #{result[:filter_answer_text]}: "
      num = []
      result[:filter_results][:total_responses].each do |response|
        num << "#{response[:dataset_label]}: <span class='number'>#{number_with_delimiter(response[:count])}</span>"
      end
      text << num.join('; ')
      filter_responses << text
    end
    title << I18n.t('explore_time_series.v1.subtitle.html.title_filter', :code => filtered_by_code, :variable => filtered_by_text, :nums => filter_responses.join)
    title << "</span>"
    return title.html_safe
  end

  def self.time_series_analysis_subtitle_text_filtered(filtered_by_code, filtered_by_text, results)
    filter_responses = []
    results.each do |result|
      text = " #{result[:filter_answer_text]}: "
      num = []
      result[:filter_results][:total_responses].each do |response|
        num << "#{response[:dataset_label]}: #{number_with_delimiter(response[:count])}"
      end
      text << num.join('; ')
      filter_responses << text
    end
    return I18n.t('explore_time_series.v1.subtitle.text.title_filter', :code => filtered_by_code, :variable => filtered_by_text, :nums => filter_responses.join('; '))
  end

end

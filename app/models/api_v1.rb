class ApiV1
  ANALYSIS_TYPE = {:single => 'single', :comparative => 'comparative', :time_series => 'time_series'}

  ########################################
  ## DATASETS
  ########################################

  # get list of all datasets
  def self.dataset_catalog
    Dataset.is_public.sorted
  end

  # get details about a dataset
  def self.dataset(dataset_id)
    dataset = Dataset.is_public.find_by(id: dataset_id)

    if dataset.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_dataset') }]}
    end

    return dataset
  end

  # get codebook for a dataset
  def self.dataset_codebook(dataset_id)
    questions = nil
    dataset = Dataset.is_public.find_by(id: dataset_id)

    if dataset.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_dataset') }]}
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
  #  - chart_formatted_data - boolean indicating if results should include data formatted for highcharts (optional, default false)
  #  - map_formatted_data - boolean indicating if results should include data formatted for highmaps (optional, default false)
  # return format:
  # {
  #   dataset: {id, title},
  #   question: {code, original_code, text, answers: [{value, text, can_exclude}]},
  #   broken_down_by: {code, original_code, text, answers: [{value, text, can_exclude}]} (optional),
  #   filtered_by: {code, original_code, text, answers: [{value, text, can_exclude}]} (optional),
  #   analysis_type: single/comparative (single means results will be hash while comparative means results will be array)
  #   results: {total_responses, analysis: [{answer_value, answer_text, count, percent}, ...]}
  #   chart: {data: [{name, y(percent), count, answer_value}, ...] } (optional)
  #   map: {question_code, data: [{shape_name, display_name, value, count}, ...] } (optional)
  #   errors: [{status, detail}] (optional)
  # }  
  def self.dataset_analysis(dataset_id, question_code, options={})
    data = {}
    dataset = Dataset.is_public.find_by(id: dataset_id)

    # if the dataset could not be found, stop
    if dataset.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_dataset') }]}
    end

    question = dataset.questions.with_code(question_code)

    # if the question could not be found, stop
    if question.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_question') }]}
    end

    ########################
    # get options
    can_exclude = options[:can_exclude].present? && options[:can_exclude].to_bool == true
    chart_formatted_data = options[:chart_formatted_data].present? && options[:chart_formatted_data].to_bool == true
    map_formatted_data = options[:map_formatted_data].present? && options[:map_formatted_data].to_bool == true

    # if filter by by exists, get it
    filtered_by = nil
    if options[:filtered_by_code].present?
      filtered_by = dataset.questions.with_code(options[:filtered_by_code].strip)

      # if the filter by question could not be found, stop
      if filtered_by.nil?
        return {errors: [{status: '404', detail: I18n.t('api.msgs.no_filtered_by') }]}
      end
    end

    # if broken down by exists, get it
    broken_down_by = nil
    if options[:broken_down_by_code].present?
      broken_down_by = dataset.questions.with_code(options[:broken_down_by_code].strip)

      # if the broken_down_by by question could not be found, stop
      if broken_down_by.nil?
        return {errors: [{status: '404', detail: I18n.t('api.msgs.no_broken_down_by') }]}
      end
    end

    ########################
    # start populating the output
    data[:dataset] = {id: dataset.id, title: dataset.title}
    data[:question] = create_dataset_question_hash(question, can_exclude)    
    data[:broken_down_by] = create_dataset_question_hash(broken_down_by, can_exclude) if broken_down_by.present?
    data[:filtered_by] = create_dataset_question_hash(filtered_by, can_exclude) if filtered_by.present?
    data[:analysis_type] = nil
    data[:results] = nil

    ########################
    # do the analysis
    # if there is no broken down by then do single analysis, else do comparative analysis
    # use the data[] for the parameter values to get answers that should be included in analysis
    if broken_down_by.present?
      data[:analysis_type] = ANALYSIS_TYPE[:comparative]
      data[:results] = dataset_comparative_analysis(dataset, data[:question], data[:broken_down_by], data[:filtered_by])
      data[:chart] = dataset_comparative_chart(data) if chart_formatted_data
      data[:map] = dataset_comparative_map(question.answers, broken_down_by.answers, data, question.is_mappable?) if map_formatted_data && (question.is_mappable? || broken_down_by.is_mappable?)
    else
      data[:analysis_type] = ANALYSIS_TYPE[:single]
      data[:results] = dataset_single_analysis(dataset, data[:question], data[:filtered_by])
      data[:chart] = dataset_single_chart(data) if chart_formatted_data
      data[:map] = dataset_single_map(question.answers, data) if map_formatted_data && question.is_mappable?
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
  def self.time_series(time_series_id)
    time_series = TimeSeries.is_public.find_by(id: time_series_id)

    if time_series.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_time_series') }]}
    end

    return time_series
  end

  # get codebook for a time_series
  def self.time_series_codebook(time_series_id)
    questions = nil
    time_series = TimeSeries.is_public.find_by(id: time_series_id)

    if time_series.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_time_series') }]}
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
  #  - chart_formatted_data - boolean indicating if results should include data formatted for highcharts (optional, default false)
  # return format:
  # {
  #   time_series: {id, title},
  #   datasets: [{id, title, lable}, ...],
  #   question: {code, original_code, text, answers: [{value, text, can_exclude}]},
  #   filtered_by: {code, original_code, text, answers: [{value, text, can_exclude}]} (optional),
  #   analysis_type: single (will always be single)
  #   results: {total_responses, analysis: [{dataset_label, answer_text, count, percent}, ...]}
  #   chart: {data: [{y(percent), count}, ...] } (optional)
  #   errors: [{status, detail}] (optional)
  # }  
  def self.time_series_analysis(time_series_id, question_code, options={})
    data = {}
    time_series = TimeSeries.is_public.find_by(id: time_series_id)

    # if the time_series could not be found, stop
    if time_series.nil?
      return {errors: [{status: '404', detail: I18n.t('api.msgs.no_time_series') }]}
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


    ########################
    # get options
    can_exclude = options[:can_exclude].present? && options[:can_exclude].to_bool == true
    chart_formatted_data = options[:chart_formatted_data].present? && options[:chart_formatted_data].to_bool == true

    # if filter by by exists, get it
    filtered_by = nil
    if options[:filtered_by_code].present?
      filtered_by = time_series.questions.with_code(options[:filtered_by_code].strip)

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

    data[:results] = time_series_single_analysis(data[:datasets], individual_results, data[:question], data[:filtered_by])
    data[:chart] = time_series_single_chart(data) if chart_formatted_data

    return data
  end


  ########################################
  ########################################
  ########################################
  ########################################
private
  # create question hash for a dataset
  def self.create_dataset_question_hash(question, can_exclude=false)
    hash = {}
    if question.present?
      hash = {code: question.code, original_code: question.original_code, text: question.text}
      hash[:answers] = (can_exclude == true ? question.answers.must_include_for_analysis : question.answers.all_for_analysis).map{|x| {value: x.value, text: x.text, can_exclude: x.can_exclude}}
    end

    return hash
  end



  # for the given dataset and question, do a single analysis
  def self.dataset_single_analysis(dataset, question, filtered_by=nil)
    # get the data for this code
    data = dataset.data_items.code_data(question[:code])

    # if filter provided, then get data for filter
    # and then only pull out the code data that matches
    if filtered_by.present?
      filter_data = dataset.data_items.code_data(filtered_by[:code]) if filtered_by.present?
      if filter_data.present?
        # merge the data and filter
        # and then pull out the data that has the corresponding filter value
        merged_data = filter_data.zip(data)
        filter_results = []
        filtered_by[:answers].each do |filter_answer|
          filter_item = {filter_answer_value: filter_answer[:value], filter_answer_text: filter_answer[:text], filter_results: nil}
          filter_item[:filter_results] = dataset_single_analysis_processing(question, merged_data.select{|x| x[0].to_s == filter_answer[:value].to_s}.map{|x| x[1]})
          filter_results << filter_item
        end

        return filter_results
      end
    else
      return dataset_single_analysis_processing(question, data)
    end

  end



  # for the given question and it's data, do a single analysis and convert into counts and percents
  def self.dataset_single_analysis_processing(question, data)
    results = {total_responses: 0, analysis: []}

    if data.present?
      # do not want to count nil values
      counts_per_answer = data.select{|x| x.present?}
                            .each_with_object(Hash.new(0)) { |item,counts| counts[item.to_s] += 1 }


      if counts_per_answer.present?
        # record the total response
        results[:total_responses] = counts_per_answer.values.inject(:+)

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
  # return format: 
  # - no filter: {:data => [ {name, y(percent), count, answer_value}, ...] }
  # - with filter: [ {filter_answer_value, filter_answer_text, filter_results => [ {:data => [ {name, y(percent), count, answer_value}, ...] } ] } ]
  def self.dataset_single_chart(data)
    if data.present?
      chart = nil
      if data[:filtered_by].present?
        chart = []
        data[:results].each do |filter|
          chart_item = {filter_answer_value: filter[:filter_answer_value], filter_answer_text: filter[:filter_answer_text], filter_results: {data: []}}
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
  # return format: 
  # - no filter: {data => [ {shape_name, display_name, value, count}, ... ] }
  # - with filter: [ {filter_answer_value, filter_answer_text, filter_results => [ {data => [ {shape_name, display_name, value, count}, ... ] } ] } ]
  def self.dataset_single_map(answers, data)
    if answers.present? && data.present?
      map = nil

      if data[:filtered_by].present?
        map = []
        data[:results].each do |filter|
          map_item = {filter_answer_value: filter[:filter_answer_value], filter_answer_text: filter[:filter_answer_text], 
                    filter_results: {question_code: data[:question][:code], data: []}}

          answers.each_with_index do |answer|
            data_result = filter[:filter_results][:analysis].select{|x| x[:answer_value] == answer.value}.first
            if data_result.present?
              map_item[:filter_results][:data] << dataset_single_map_processing(answer, data_result)
            end
          end

          if map_item[:filter_results][:data].present?
            map << map_item
          end
        end

      else
        map = {}

        # need question code so know which shape data to use
        map[:question_code] = data[:question][:code]

        # load the data
        map[:data] = []
        answers.each_with_index do |answer|
          data_result = data[:results][:analysis].select{|x| x[:answer_value] == answer.value}.first
          if data_result.present?
            map[:data] << dataset_single_map_processing(answer, data_result)
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
  def self.dataset_comparative_analysis(dataset, question, broken_down_by, filtered_by=nil)
    # get the values for the codes from the data
    question_data = dataset.data_items.code_data(question[:code])
    broken_down_data = dataset.data_items.code_data(broken_down_by[:code])

    # merge the data arrays into one array that 
    # has nested arrays
    data = question_data.zip(broken_down_data)

    # if filter provided, then get data for filter
    # and then only pull out the code data that matches
    if filtered_by.present?
      filter_data = dataset.data_items.code_data(filtered_by[:code]) if filtered_by.present?
      if filter_data.present?
        # merge the data and filter
        # and then pull out the data that has the corresponding filter value
        merged_data = filter_data.zip(data)
        filter_results = []
        filtered_by[:answers].each do |filter_answer|
          filter_item = {filter_answer_value: filter_answer[:value], filter_answer_text: filter_answer[:text], filter_results: nil}
          filter_item[:filter_results] = dataset_comparative_analysis_processing(question, broken_down_by, merged_data.select{|x| x[0].to_s == filter_answer[:value].to_s}.map{|x| x[1]})
          filter_results << filter_item
        end

        return filter_results
      end
    else
      return dataset_comparative_analysis_processing(question, broken_down_by, data)
    end

  end



  # for the given dataset, question and broken down by question, do a comparative analysis and convert into counts and percents
  # data is an array of [question answer, broken down by answer]
  def self.dataset_comparative_analysis_processing(question, broken_down_by, data)
    results = {total_responses: 0, analysis: []}
    analysis = results[:analysis]
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

      end

    end
    return results
  end


  # convert the results into stacked bar chart format
  # return format: 
  # - no filter: {:data => [ {name, y(percent), count, answer_value}, ...] }
  # - with filter: [ {filter_answer_value, filter_results => [ {:data => [ {name, y(percent), count, answer_value}, ...] } ] } ]
  def self.dataset_comparative_chart(data)
    if data.present?
      chart = nil
      if data[:filtered_by].present?
        chart = []
        data[:results].each do |filter|
          chart_item = {filter_answer_value: filter[:filter_answer_value], filter_answer_text: filter[:filter_answer_text], filter_results: {labels: [], data: []}}
          chart_item[:filter_results][:labels] = data[:question][:answers].map{|x| x[:text]}

          # have to transpose the counts for highcharts
          counts = filter[:filter_results][:analysis].map{|x| x[:broken_down_results].map{|y| y[:count]}}.transpose

          data[:broken_down_by][:answers].each_with_index do |answer, i|
            chart_item[:filter_results][:data] << {name: answer[:text], data: counts[i]}
          end

          if chart_item[:filter_results][:data].present?
            chart << chart_item
          end
        end
      else
        chart = {}

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


  # return format: {:data => [ {name, y(percent), count, answer_value}, ...] }
  def self.dataset_comparative_chart_processing(answer, data_result)
    {
      name: answer[:text], 
      y: data_result[:percent], 
      count: data_result[:count], 
      answer_value: answer[:value]
    }
  end



  # convert the results into highmaps map format
  # return format: 
  # - no filter: {data => [ {shape_name, display_name, value, count}, ... ] }
  # - with filter: [ {filter_answer_value, filter_answer_text, filter_results => [ {data => [ {shape_name, display_name, value, count}, ... ] } ] } ]
  def self.dataset_comparative_map(question_answers, broken_down_by_answers, data, question_mappable=true)
    if question_answers.present? && broken_down_by_answers.present? && data.present?
      map = nil

      if data[:filtered_by].present?
        map = []
        data[:results].each do |filter|
          map_item = {filter_answer_value: filter[:filter_answer_value], filter_answer_text: filter[:filter_answer_text], 
                    filter_results: {question_code: nil, data: []}}


          if question_mappable
            # need question code so know which shape data to use
            map_item[:filter_results][:question_code] = data[:question][:code]

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

            broken_down_by_answers.each_with_index do |bdb_answer, bdb_index|
              item = {broken_down_answer_value: bdb_answer.value, broken_down_answer_text: bdb_answer.text, data: []}
              
              question_answers.each_with_index do |q_answer, q_index|
                item[:data] << dataset_comparative_map_processing(q_answer, percents[bdb_index][q_index], counts[bdb_index][q_index])
              end
              map_item[:filter_results][:data] << item
            end        
          else
            # need question code so know which shape data to use
            map_item[:filter_results][:question_code] = data[:broken_down_by][:code]

            counts = filter[:filter_results][:analysis].map{|x| x[:broken_down_results].map{|y| y[:count]}}
            percents = filter[:filter_results][:analysis].map{|x| x[:broken_down_results].map{|y| y[:percent]}}

            question_answers.each_with_index do |q_answer, q_index|
              item = {broken_down_answer_value: q_answer.value, broken_down_answer_text: q_answer.text, data: []}
              
              broken_down_by_answers.each_with_index do |bdb_answer, bdb_index|
                item[:data] << dataset_comparative_map_processing(bdb_answer, percents[q_index][bdb_index], counts[q_index][bdb_index])
              end
              map_item[:filter_results][:data] << item
            end        
          end

          if map_item[:filter_results][:data].present?
            map << map_item
          end
        end

      else
        map = {}
        map[:question_code] = nil
        map[:data] = []

        if question_mappable
          # need question code so know which shape data to use
          map[:question_code] = data[:question][:code]

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
            item = {broken_down_answer_value: bdb_answer.value, broken_down_answer_text: bdb_answer.text, data: []}
            
            question_answers.each_with_index do |q_answer, q_index|
              item[:data] << dataset_comparative_map_processing(q_answer, percents[bdb_index][q_index], counts[bdb_index][q_index])
            end
            map[:data] << item
          end        
        else
          # need question code so know which shape data to use
          map[:question_code] = data[:broken_down_by][:code]

          counts = data[:results][:analysis].map{|x| x[:broken_down_results].map{|y| y[:count]}}
          percents = data[:results][:analysis].map{|x| x[:broken_down_results].map{|y| y[:percent]}}

          question_answers.each_with_index do |q_answer, q_index|
            item = {broken_down_answer_value: q_answer.value, broken_down_answer_text: q_answer.text, data: []}
            
            broken_down_by_answers.each_with_index do |bdb_answer, bdb_index|
              item[:data] << dataset_comparative_map_processing(bdb_answer, percents[q_index][bdb_index], counts[q_index][bdb_index])
            end
            map[:data] << item
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
          hash = {dataset_id: dataset.dataset_id, title: dataset.dataset.title, label: dataset.title}
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
      hash = {code: question.code, original_code: question.original_code, text: question.text}
      hash[:answers] = (can_exclude == true ? question.answers.must_include_for_analysis : question.answers.sorted).map{|x| {value: x.value, text: x.text, can_exclude: x.can_exclude}}
    end

    return hash
  end


  # for the given time_series and question, do a single analysis
  def self.time_series_single_analysis(datasets, individual_results, question, filtered_by=nil)
    # if filter provided, then get data for filter
    # and then only pull out the code data that matches
    if filtered_by.present?
      filter_results = []
      filtered_by[:answers].each do |filter_answer|
        filter_item = {filter_answer_value: filter_answer[:value], filter_answer_text: filter_answer[:text], filter_results: nil}
        filter_item[:filter_results] = time_series_single_analysis_processing(datasets, individual_results, question, filter_answer[:value])
        filter_results << filter_item
      end

      return filter_results
    else
      return time_series_single_analysis_processing(datasets, individual_results, question)
    end

  end



  # for the given question and it's data, do a single analysis and convert into counts and percents
  def self.time_series_single_analysis_processing(datasets, individual_results, question, filter_answer_values=nil)
    results = {total_responses: [], analysis: []}

    question[:answers].each do |answer|
      answer_item = {answer_value: answer[:value], answer_text: answer[:text], dataset_results: []}

      datasets.each do |dataset|
        dataset_item = {dataset_label: dataset[:label], dataset_title: dataset[:title], count: 0, percent: 0}

        # see if this dataset had results
        individual_result = individual_results.select{|x| x[:dataset_id] == dataset[:dataset_id]}.first
        if individual_result.present?
          # get results from dataset
          dataset_answer_results = nil
          if filter_answer_values.present?
            filter_results = individual_result[:dataset_results][:results].select{|x| x[:filter_answer_value] == filter_answer_values}.first
            dataset_answer_results = filter_results[:filter_results][:analysis].select{|x| x[:answer_value] == answer[:value]}.first if filter_results.present?
          else
            dataset_answer_results = individual_result[:dataset_results][:results][:analysis].select{|x| x[:answer_value] == answer[:value]}.first
          end
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
      individual_result = individual_results.select{|x| x[:dataset_id] == dataset[:dataset_id]}.first
      if individual_result.present?
        if filter_answer_values.present?
          filter_results = individual_result[:dataset_results][:results].select{|x| x[:filter_answer_value] == filter_answer_values}.first
          response_item[:count] = filter_results[:filter_results][:total_responses] if filter_results.present?
        else
          response_item[:count] = individual_result[:dataset_results][:results][:total_responses]
        end
      end

      results[:total_responses] << response_item
    end

    return results
  end


  # convert the results into pie chart format
  # return format: 
  # - no filter: {:data => [ {name, y(percent), count, answer_value}, ...] }
  # - with filter: [ {filter_answer_value, filter_answer_text, filter_results => [ {:data => [ {name, y(percent), count, answer_value}, ...] } ] } ]
  def self.time_series_single_chart(data)
    if data.present?
      chart = nil
      if data[:filtered_by].present?
        chart = []
        data[:results].each do |filter|
          chart_item = {filter_answer_value: filter[:filter_answer_value], filter_answer_text: filter[:filter_answer_text], filter_results: {data: []}}
          data[:question][:answers].each do |answer|
            data_result = filter[:filter_results][:analysis].select{|x| x[:answer_value] == answer[:value]}.first
            if data_result.present?
              chart_item[:filter_results][:data] << time_series_single_chart_processing(answer, data_result)
            end
          end
          if chart_item[:filter_results][:data].present?
            chart << chart_item
          end
        end
      else
        chart = {}
        chart[:data] = []
        data[:question][:answers].each do |answer|
          data_result = data[:results][:analysis].select{|x| x[:answer_value] == answer[:value]}.first
          if data_result.present?
            chart[:data] << time_series_single_chart_processing(answer, data_result)
          end
        end
      end
      
      return chart
    end
  end


  # format: {name, y(percent), count, answer_value}
  def self.time_series_single_chart_processing(answer, data_result)
    {
      name: answer[:text], 
      y: data_result[:percent], 
      count: data_result[:count], 
      answer_value: answer[:value]
    }
  end
end
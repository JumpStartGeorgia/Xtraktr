class ApiV1
  ANALYSIS_TYPE = {:simple => 'simple', :comparative => 'comparative'}

  ########################################
  ## DATASETS
  ########################################

  # get list of all datasets
  def self.dataset_catalog
    Dataset.is_public.sorted
  end

  # get details about a dataset
  def self.dataset(dataset_id)
    Dataset.is_public.find_by(id: dataset_id)
  end

  # get codebook for a dataset
  def self.dataset_codebook(dataset_id)
    questions = nil
    dataset = Dataset.is_public.find_by(id: dataset_id)

    if dataset.present?
      questions = dataset.questions.for_analysis
    end

    return questions
  end

  
  # analyse the dataset for the passed in parameters
  # parameters:
  #  - dataset_id - id of dataset to analyze (required)
  #  - question_code - code of question to analyze (required)
  #  - broken_down_by_code - code of question to compare against the first question (optional)
  #  - filtered_by_code - code of question to filter the analysis by (optioanl)
  #  - can_exclude - boolean indicating if the can_exclude answers should by excluded (optional, default false)
  # return format:
  # {
  #   dataset: {id, title},
  #   question: {code, original_code, text, answers: [{value, text, can_exclude}]},
  #   errors: [{status, detail}]
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
    # if there is no broken down by then do simple analysis, else do comparative analysis
    # use the data[] for the parameter values to get answers that should be included in analysis
    if broken_down_by.present?
      data[:analysis_type] = ANALYSIS_TYPE[:comparative]
      data[:results] = dataset_comparative_analysis(dataset, data[:question], data[:broken_down_by], data[:filtered_by])
    else
      data[:analysis_type] = ANALYSIS_TYPE[:simple]
      data[:results] = dataset_simple_analysis(dataset, data[:question], data[:filtered_by])
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
    TimeSeries.is_public.find_by(id: time_series_id)
  end

  # get codebook for a time_series
  def self.time_series_codebook(time_series_id)
    questions = nil
    time_series = TimeSeries.is_public.find_by(id: time_series_id)

    if time_series.present?
      questions = time_series.questions.sorted
    end

    return questions
  end




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



  # for the given dataset and question, do a simple analysis
  def self.dataset_simple_analysis(dataset, question, filtered_by=nil)
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
          filter_item = {filter_answer_value: filter_answer[:value], filter_results: nil}
          filter_item[:filter_results] = dataset_simple_analysis_processing(question, merged_data.select{|x| x[0].to_s == filter_answer[:value].to_s}.map{|x| x[1]})
          filter_results << filter_item
        end

        return filter_results
      end
    else
      return dataset_simple_analysis_processing(question, data)
    end

  end



  # for the given question and it's data, do a simple analysis and convert into counts and percents
  def self.dataset_simple_analysis_processing(question, data)
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
          item = {answer_value: answer[:value], count: 0, percent: 0}
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
          filter_item = {filter_answer_value: filter_answer[:value], filter_results: nil}
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
    question_answer_template = {answer_value: nil, broken_down_results: nil}
    broken_down_answer_template = {broken_down_answer_value: nil, count: 0, percent: 0}

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
          item[:broken_down_results] = []

          broken_down_by[:answers].each do |bdb_answer|
            bdb_item = broken_down_answer_template.clone
            bdb_item[:broken_down_answer_value] = bdb_answer[:value]

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


end
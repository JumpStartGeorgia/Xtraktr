class ApiV1

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

  # 
  # def self.dataset_simple_analysis(dataset_id, question_code)
  #   data = nil
  #   dataset = Dataset.is_public.find_by(id: dataset_id)

  #   if dataset.present?
      
  #   end

  #   return data
  # end

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







end
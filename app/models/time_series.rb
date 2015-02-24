class TimeSeries < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  field :title, type: String, localize: true
  field :description, type: String, localize: true
  field :source, type: String, localize: true
  field :source_url, type: String, localize: true
  # whether or not dataset can be shown to public
  field :public, type: Boolean, default: false
  # key to access dataset that is not public
  field :private_share_key, type: String

  embeds_many :datasets, class_name: 'TimeSeriesDataset' do
    def sorted
      order_by([[:sort_order, :asc]]).to_a
    end
  end

  embeds_many :questions, class_name: 'TimeSeriesQuestion' do
    # get the question that has the provided code
    def with_code(code)
      where(:code => code.downcase).first
    end

    # get the dataset question records for the provided code
    def dataset_questions_in_code(code)
      with_code(code).dataset_questions
    end
  
      # get questions that are not excluded and have code answers
    def for_analysis
      where(:exclude => false, :has_code_answers => true).to_a
    end
    
end

  #############################

  accepts_nested_attributes_for :datasets
  accepts_nested_attributes_for :questions

  attr_accessible :title, :description,
      :datasets_attributes, :questions_attributes

  #############################
  # indexes
  index ({ :title => 1})
  index ({ :public => 1})
  index ({ :'questions.code' => 1})
  index ({ :'questions.text' => 1})
  index ({ :'questions.has_code_answers' => 1})
  index ({ :'questions.exclude' => 1})
  index ({ :'datasets.sort_order' => 1})
  index ({ :'datasets.dataset_id' => 1})

  #############################
  # Validations
  validates_presence_of :title

  #############################
  # Scopes

  def self.sorted
    order_by([[:title, :asc]])
  end

  def self.is_public
    where(public: true)
  end

  def self.by_private_key(key)
    where(private_share_key: key).first
  end

  #############################

  ### perform a summary analysis of one question_code over time
  ### - question_code: code of question to analyze over time
  # - options:
  #   - filter: if provided, indicates a field and value to filter the data by
  #           format: {code: ____, value: ______}
  #   - exclude_dkra: flag indicating if don't know/refuse to answer answers should be ignored
  def data_onevar_analysis(question_code, options={})
    start = Time.now

    filter = options[:filter]
    exclude_dkra = options[:exclude_dkra] == true
    logger.debug "//////////// data_onevar_analysis - question_code: #{question_code}, filter: #{filter}, exclude_dkra: #{exclude_dkra}"

    result = {}

    # get the question/answers
    result[:row_code] = question_code
    row_question = self.questions.with_code(question_code)
    result[:row_question] = row_question.text
    # if exclude_dkra is true, only get use the answers that cannot be excluded
    result[:row_answers] = (exclude_dkra == true ? row_question.answers.must_include_for_analysis : row_question.answers.all_for_analysis).sort_by{|x| x.sort_order}
    result[:type] = 'time_series'
    result[:chart] = {}

    dataset_questions = self.questions.dataset_questions_in_code(question_code)
    datasets = self.datasets.sorted
    result[:datasets] = datasets.map{|x| x.title}

    # if the row question/answers were found, continue
    if result[:row_question].present? && datasets.present? && dataset_questions.present? && result[:row_answers].present?
      individual_results = []
      dataset_questions.each do |dq|
        x = dq.dataset.data_onevar_analysis(question_code, options)
        if x.present?
          individual_results << {dataset_id: dq.dataset_id, results:x}
        end
      end

      if individual_results.present?
        # now need to group the results into the time series format
        # chart data = [{name: '', data: []}, ...]
        result[:chart][:data] = []
        result[:row_answers].each do |answer|
          answer_data = {name: answer.text, data:[]}
          datasets.each do |dataset|
            # see if this dataset had results
            results = individual_results.select{|x| x[:dataset_id] == dataset.dataset_id}.first
            if results.present?
              # get index of answer in results so can pull out data
              result_answer = results[:results][:chart][:data].select{|x| x[:answer_value] == answer.value}.first
              if result_answer.present?
                answer_data[:data] << {y: result_answer[:y], count: result_answer[:count]}
              end
            end
          end

          if answer_data[:data].present?
            result[:chart][:data] << answer_data
          end
        end

      end

    end

    logger.debug "== total time = #{(Time.now - start)*1000} ms"
    return result
  end
end

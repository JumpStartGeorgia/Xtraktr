class TimeSeries < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  belongs_to :user

  #############################

  field :title, type: String, localize: true
  field :description, type: String, localize: true
  # whether or not dataset can be shown to public
  field :public, type: Boolean, default: false
  # key to access dataset that is not public
  field :private_share_key, type: String
  field :languages, type: Array
  field :default_language, type: String

  embeds_many :datasets, class_name: 'TimeSeriesDataset' do
    def sorted
      order_by([[:sort_order, :asc], [:title, :asc]]).to_a
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
    
    def sorted
      order_by([[:code, :asc]])
    end
end

  #############################

  accepts_nested_attributes_for :datasets, reject_if: :all_blank
  accepts_nested_attributes_for :questions, reject_if: :all_blank

  attr_accessible :title, :description, :user_id, 
      :public, :private_share_key, 
      :datasets_attributes, :questions_attributes,
      :languages, :default_language,
      :title_translations, :description_translations

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
  validates_presence_of :default_language
  validate :validate_languages
  validate :validate_translations
  validate :validate_dataset_presence

  # validate that at least one item in languages exists
  def validate_languages
    # first remove any empty items
    self.languages.delete("")
    logger.debug "***** validates languages: #{self.languages.blank?}"
    if self.languages.blank?
      errors.add(:languages, I18n.t('errors.messages.blank'))
    else
      # make sure each locale in languages is in Language
      self.languages.each do |locale|
        if Language.where(:locale => locale).count == 0
          errors.add(:languages, I18n.t('errors.messages.invalid_language', lang_locale: locale))
        end
      end
    end
  end

  # validate the translation fields
  # title field need to be validated for presence
  def validate_translations
    logger.debug "***** validates dataset translations"
    if self.default_language.present?
      logger.debug "***** - default is present; title = #{self.title_translations[self.default_language]}"
      if self.title_translations[self.default_language].blank?
        logger.debug "***** -- title not present!"
        errors.add(:base, I18n.t('errors.messages.translation_default_lang', 
            field_name: self.class.human_attribute_name('title'),
            language: Language.get_name(self.default_language),
            msg: I18n.t('errors.messages.blank')) )
      end
    end
  end 

  # make sure at least two datasets exist
  def validate_dataset_presence
    if self.datasets.blank? || self.datasets.length < 2
      logger.debug "***** -- not enough datasets!"
      errors.add(:base, I18n.t('errors.messages.dataset_length'))
    end
  end

  #############################
  ## override get methods for fields that are localized
  def title
    get_translation(self.title_translations)
  end
  def description
    get_translation(self.description_translations)
  end


  #############################
  # Callbacks
  before_create :create_private_share_key

  # create private share key that allows people to access this dataset if it is not public
  def create_private_share_key
    if self.private_share_key.blank?
      self.private_share_key = SecureRandom.hex
    end
    return true
  end


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

  def self.by_user(user_id)
    where(user_id: user_id)
  end

  # get the record if the user is the owner
  def self.by_id_for_user(id, user_id)
    where(id: id).by_user(user_id).first
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

class TimeSeriesWeight < CustomTranslation
  include Mongoid::Document

  #############################

  belongs_to :dataset

  #############################
  field :code, type: String
  field :text, type: String, localize: true
  field :is_default, type: Boolean, default: false
  field :applies_to_all, type: Boolean, default: false
  field :codes, type: Array, default: []

  #############################
  embedded_in :time_series

  embeds_many :assignments, class_name: 'TimeSeriesWeightAssignment', cascade_callbacks: true do
    # get the assignment for a dataset
    def with_dataset(dataset_id)
      where(dataset_id: dataset_id).first
    end

    # get the weight values for a dataset
    def dataset_weight_values(dataset_id)
      x = where(dataset_id: dataset_id).first
      if x.present?
        x.weight_values
      else
        return nil
      end
    end

  end
  accepts_nested_attributes_for :assignments

  #############################
  attr_accessible :code, :text, :text_translations, :is_default, :codes, :applies_to_all, :dataset_id, :assignments_attributes

  #############################
  # Validations
  validates_presence_of :code, :dataset_id
  validates :codes, :presence => true, :unless => Proc.new { |x| x.applies_to_all? || x.is_default || (x.codes.is_a?(Array) && x.codes.empty?) }
  validate :validate_translations

  # validate the translation fields
  # text field needs to be validated for presence
  def validate_translations
#    logger.debug "***** validates question translations"
    if self.time_series.default_language.present?
#      logger.debug "***** - default is present; text = #{self.text_translations[self.time_series.default_language]}"
      if self.text_translations[self.time_series.default_language].blank?
#        logger.debug "***** -- text not present!"
        errors.add(:base, I18n.t('errors.messages.translation_default_lang',
            field_name: self.class.human_attribute_name('text'),
            language: Language.get_name(self.time_series.default_language),
            msg: I18n.t('errors.messages.blank')) )
      end
    end
  end

  #############################
  # Callbacks
  before_save :reset_fields
  before_save :set_question_flags
  before_save :generate_weight_values
  before_destroy :reset_question_flags

  # if is default or applies to all is true, codes should be empty
  def reset_fields
    if self.is_default?
      self.applies_to_all = true
      self.codes = []
    elsif self.applies_to_all?
      self.codes = []
    end

    return true
  end

  # the weight question must be included in the download and set flag indicating question is weight
  def set_question_flags
    q = self.time_series.questions.with_code(code)
    if q.present?
      q.is_weight = true
      q.exclude = true
      q.can_download = true
      q.save
    end
  end

  # indicate that this question is not a weight
  def reset_question_flags
    q = self.time_series.questions.with_code(code)
    if q.present?
      q.is_weight = false
      q.save
    end
  end

  # get the weight values and then for each dataset, get the unique ids and re-order the weight values to be in the correct order
  # - doing this so analysis is simple and just need to pass in the weight values for each dataset
  # - if the weight values do not have a value for an ID, give it a value of 0
  # - only need to run this if the dataset id, weight code or assignment code unique id changed
  def generate_weight_values
    puts "generate_weight_values: start"
    assingment_changed = self.assignments.map{|x| x.code_unique_id_changed?}.include?(true)
    puts "- dataset id changed = #{self.dataset_id_changed?}; code changed = #{self.code_changed?}; assignment changed = #{assingment_changed}"
    if self.dataset_id_changed? || self.code_changed? || assingment_changed
      puts "- something changed, re-generated weight value arrays"
      # for each dataset, get unique ids
      # also get the weight values from the dataset that has the unique values
      weight_values = nil
      dataset_unique_ids = {}
      self.time_series.datasets.dataset_ids.each do |dataset_id|
        # if this is the dataset with the weight, get the weight values
        if dataset_id == self.dataset_id
          weight_values = DataItem.dataset_code_data(dataset_id, self.code)
        end

        # get the unique id values for this dataset
        assignment = self.assignments.with_dataset(dataset_id)
        dataset_unique_ids[dataset_id] = []
        if assignment.present?
          dataset_unique_ids[dataset_id] = DataItem.dataset_code_data(dataset_id, assignment.code_unique_id)
        end
      end

      if weight_values.present? && dataset_unique_ids.keys.present?
        # for each dataset, re-arrange the weight values to be in the correct order for the dataset
        dataset_unique_ids.keys.each do |dataset_id|
          assignment = self.assignments.with_dataset(dataset_id)

          # if the dataset is the dataset that has the weight, no work is needed to be done
          # for the weights are already in the correct order
          if dataset_id == self.dataset_id
            assignment.weight_values = weight_values
          else
            # look for the unique id in the dataset that has the weight
            # if found, use the index to get the weight value, else 0
            dataset_weight_values = []
            dataset_unique_ids[dataset_id].each do |data_item|
              index = dataset_unique_ids[self.dataset_id].index{|x| x == data_item}
              if index.present?
                dataset_weight_values << weight_values[index]
              else
                dataset_weight_values << 0
              end
            end
            assignment.weight_values = dataset_weight_values
          end
        end
      else
        # reset the assignment weight values to nil
        self.assignments.each do |assignment|
          assignment.weight_values = nil
        end
      end
    end
  end

  #############################
  ## override get methods for fields that are localized
  def text
    # if the title is not present, show the code
    get_translation(self.text_translations, self.time_series.current_locale, self.time_series.default_language)
  end

  #############################

  # get the question that is the weight
  def source_question
    self.dataset.questions.with_code(self.code)
  end

  # get questions that this weight applies to
  def applies_to_questions
    self.time_series.questions.with_codes(self.codes)
  end

  #############################

end

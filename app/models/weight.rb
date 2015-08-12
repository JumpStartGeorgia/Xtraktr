class Weight < CustomTranslation
  include Mongoid::Document

  field :code, type: String
  field :text, type: String, localize: true
  field :is_default, type: Boolean, default: false
  field :applies_to_all, type: Boolean, default: false
  field :codes, type: Array, default: []

  #############################
  embedded_in :dataset

  #############################
  attr_accessible :code, :text, :text_translations, :is_default, :codes, :applies_to_all

  #############################
  # Validations
  validates_presence_of :code
  validates :codes, :presence => true, :unless => Proc.new { |x| x.applies_to_all? || x.is_default || (x.codes.is_a?(Array) && x.codes.empty?) }
  validate :validate_translations

  # validate the translation fields
  # text field needs to be validated for presence
  def validate_translations
#    logger.debug "***** validates question translations"
    if self.dataset.default_language.present?
#      logger.debug "***** - default is present; text = #{self.text_translations[self.dataset.default_language]}"
      if self.text_translations[self.dataset.default_language].blank?
#        logger.debug "***** -- text not present!"
        errors.add(:base, I18n.t('errors.messages.translation_default_lang',
            field_name: self.class.human_attribute_name('text'),
            language: Language.get_name(self.dataset.default_language),
            msg: I18n.t('errors.messages.blank')) )
      end
    end
  end

  #############################
  # Callbacks
  before_save :reset_fields
  before_save :set_question_flags
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
    q = self.dataset.questions.with_code(code)
    if q.present?
      q.is_weight = true
      q.exclude = true
      q.can_download = true
      q.save
    end
  end

  # indicate that this question is not a weight
  def reset_question_flags
    q = self.dataset.questions.with_code(code)
    if q.present?
      q.is_weight = false
      q.save
    end
  end

  #############################
  ## override get methods for fields that are localized
  def text
    # if the title is not present, show the code
    get_translation(self.text_translations, self.dataset.current_locale, self.dataset.default_language)
  end

  #############################

  # get the question that is the weight
  def source_question
    self.dataset.questions.with_code(self.code)
  end

  # get questions that this weight applies to
  def applies_to_questions
    self.dataset.questions.with_codes(self.codes)
  end

end

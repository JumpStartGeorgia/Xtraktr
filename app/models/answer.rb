class Answer < CustomTranslation
  include Mongoid::Document

  #############################

  field :value, type: String
  field :text, type: String, localize: true
  field :can_exclude, type: Boolean, default: false
  field :sort_order, type: Integer, default: 1
  field :exclude, type: Boolean, default: false
  # name of the shape that this answer maps to
  # - only populated if the question is mappable
  field :shape_name, type: String, localize: true

  embedded_in :question

  #############################
  # indexes
  # index ({ :can_exclude => 1})
  # index ({ :sort_order => 1})

  #############################
  attr_accessible :value, :text, :can_exclude, :sort_order, :text_translations, :exclude

  #############################
  # Validations
  validates_presence_of :value
  # validate :validate_translations ### turn off to allow answers with no text to be saved

  # validate the translation fields
  # text field needs to be validated for presence
  def validate_translations
#    logger.debug "***** validates answer translations"
    if self.question.dataset.default_language.present?
#      logger.debug "***** - default is present; locale = #{self.question.dataset.default_language}; trans = #{self.text_translations}; text = #{self.text_translations[self.question.dataset.default_language]}"
      if self.text_translations[self.question.dataset.default_language].blank?
#        logger.debug "***** -- text not present!"
        errors.add(:base, I18n.t('errors.messages.translation_default_lang', 
            field_name: self.class.human_attribute_name('text'),
            language: Language.get_name(self.question.dataset.default_language),
            msg: I18n.t('errors.messages.blank')) )
      end
    end
  end 

  #############################
  ## override get methods for fields that are localized
  def text
    get_translation(self.text_translations, self.question.dataset.current_locale, self.question.dataset.default_language)
  end
  def shape_name
    get_translation(self.shape_name_translations, self.question.dataset.current_locale, self.question.dataset.default_language)
  end

  #############################
  ## used when editing time series questions
  def to_json
    {
      value: self.value,
      text: self.text,
      text_translations: self.text_translations,
      sort_order: self.sort_order,
      can_exclude: self.can_exclude,
      exclude: self.exclude
    }
  end

end
Skip to content
This repository  
Search
Pull requests
Issues
Gist
 @antarya
 Unwatch 5
  Star 1
 Fork 0 JumpStartGeorgia/Xtraktr
 Code  Issues 0  Pull requests 0  Wiki  Pulse  Graphs
Branch: master-histogr… Find file Copy pathXtraktr/app/models/answer.rb
0d65ef5  on Sep 22
@antarya antarya Signup system refactored
2 contributors @jasonaddie @antarya
RawBlameHistory    82 lines (70 sloc)  2.72 KB
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
  validate :validate_translations

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
  # Callbacks
  # before_save :check_flags
  def check_flags
    #logger.debug "----------------- answer check flags before save"
    if exclude_changed? || can_exclude_changed?
      #logger.debug "------ answer #{self.text} exclude changed, calling question flag/stats"
      self.question.update_flags
      self.question.update_stats
    end
    return true
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
Status API Training Shop Blog About Pricing
© 2015 GitHub, Inc. Terms Privacy Security Contact Help
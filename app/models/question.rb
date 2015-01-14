class Question < CustomTranslation
  include Mongoid::Document

  #############################

  belongs_to :shapeset

  #############################


  # all codes are downcased and '.' are replaced with '|'
  field :code, type: String
  field :original_code, type: String
  field :text, type: String, localize: true
  # whether or not the questions has answers
  field :has_code_answers, type: Boolean, default: false
  # whether or not the question should not be included in the analysis
  field :exclude, type: Boolean, default: false
  # whether or not the question is tied to a shapeset
  field :is_mappable, type: Boolean, default: false

  embedded_in :dataset
  embeds_many :answers do
    # these are functions that will query the answers documents

    # get the unique answer values
    def unique_values
      only(:values).map{|x| x.values}
    end

    # get the answer that has the provide value
    def with_value(value)
      where(:value => value).first
    end

    # get answers that are not excluded
    def all_for_analysis
      where(:exclude => false).to_a
    end

    # get answers that must be included for analysis
    def must_include_for_analysis
      where(:can_exclude => false, :exclude => false).to_a
    end

    def sorted
      order_by([[:sort_order, :asc], [:text, :asc]])
    end

  end
  accepts_nested_attributes_for :answers#, :reject_if => lambda { |x| (x[:text].blank? || x[:text][x[:default_language]].blank?) || x[:value].blank? }, :allow_destroy => true

  #############################
  # indexes
  # index ({ :code => 1})
  # index ({ :text => 1})
  # index ({ :has_code_answers => 1})
  # index ({ :is_mappable => 1})

  #############################
  attr_accessible :code, :text, :original_code, :has_code_answers, :is_mappable, :answers_attributes, :exclude, :text_translations

  #############################
  # Validations
  validates_presence_of :code, :original_code
#  validate :validate_translations

  # validate the translation fields
  # text field needs to be validated for presence
  def validate_translations
    logger.debug "***** validates question translations"
    if self.dataset.default_language.present?
      logger.debug "***** - default is present; text = #{self.text_translations[self.dataset.default_language]}"
      if self.text_translations[self.dataset.default_language].blank?
        logger.debug "***** -- text not present!"
        errors.add(:base, I18n.t('errors.messages.translation_default_lang', 
            field_name: self.class.human_attribute_name('text'),
            language: Language.get_name(self.dataset.default_language),
            msg: I18n.t('errors.messages.blank')) )
      end
    end
  end 


  #############################
  ## override get methods for fields that are localized
  def text
    x = get_translation(self.text_translations, self.dataset.current_locale, self.dataset.default_language)
    return x.present? ? x : self.code
  end

  #############################

  before_save :update_flags
  before_save :check_mappable

  def update_flags
    logger.debug "updating question flags for #{self.code}"
    self.has_code_answers = self.answers.present?

    return true
  end

  # if is_mappable changed, tell the dataset to update its flag
  def check_mappable
    if self.shapeset_id_changed?
      self.is_mappable = self.shapeset_id.present?
      self.dataset.update_mappable_flag
    end
    return true
  end

  #############################


end
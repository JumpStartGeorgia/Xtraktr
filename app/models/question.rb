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
      only(:values).map{|x| x.value}
    end

    # get the answer that has the provide value
    def with_value(value)
      where(:value => value).first
    end

    # get answers that are not excluded
    def all_for_analysis
      where(:exclude => false)
        .order_by([[:sort_order, :asc], [:text, :asc]])
    end

    # get answers that must be included for analysis
    def must_include_for_analysis
      where(:can_exclude => false, :exclude => false)
        .order_by([[:sort_order, :asc], [:text, :asc]])
    end

    def sorted
      order_by([[:sort_order, :asc], [:text, :asc]])
    end

  end
  accepts_nested_attributes_for :answers, :reject_if => lambda { |x| 
    (x[:text_translations].blank? || x[:text_translations].keys.length == 0 || x[:text_translations][x[:text_translations].keys.first].blank?) && x[:value].blank? 
    }, :allow_destroy => true

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
#  validate :validate_translations # can't run this because question text might not exist

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
  ## override get methods for fields that are localized
  def text
    # if the title is not present, show the code
    x = get_translation(self.text_translations, self.dataset.current_locale, self.dataset.default_language)
    return x.present? ? x : self.original_code
  end

  #############################

  before_save :update_flags
  before_save :check_mappable
  after_save :update_stats

  def update_flags
#    logger.debug "updating question flags for #{self.code}"
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

  # if the exclude flag changes, update the dataset stats
  def update_stats
    logger.debug "@@@@@@@ question update stats"
    if self.exclude_changed?
      self.dataset.update_stats
    end
  end

  #############################

  # create a list of values that are in the data but not an answer value
  def missing_answers
    (self.dataset.data_items.unique_code_data(self.code) - self.answers.unique_values).delete_if{|x| x.nil?}
  end


  def code_with_text
    "#{self.original_code} - #{self.text}"
  end

end
class PageContent
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  field :name, type: String
  field :title, type: String, localize: true
  field :content, type: String, localize: true

  #############################
  attr_accessible :name, :title, :content, :title_translations, :content_translations

  #############################

  # indexes
  index ({ :name => 1})

  #############################
  # Validations
  validates_presence_of :name
  validates_uniqueness_of :name
  validate :validate_translations

  # validate the translation fields
  # title need to be validated for presence
  def validate_translations
    logger.debug "***** validates translations"
    default_language = I18n.default_locale.to_s
    if default_language.present?
      logger.debug "***** - default is present; title = #{self.title_translations[default_language]}"
      if self.title_translations[default_language].blank?
        errors.add(:base, I18n.t('errors.messages.translation_default_lang', 
            field_name: self.class.human_attribute_name('title'),
            language: Language.get_name(default_language),
            msg: I18n.t('errors.messages.blank')) )
      end
    end
  end 

  #############################
  # Callbacks
  before_save :set_to_nil

  # if title or content are '', reset value to nil so fallback works
  def set_to_nil
    self.title_translations.keys.each do |key|
      self.title_translations[key] = nil if !self.title_translations[key].nil? && self.title_translations[key].empty?
    end

    self.content_translations.keys.each do |key|
      self.content_translations[key] = nil if !self.content_translations[key].nil? && self.content_translations[key].empty?
    end
  end 

  #############################

  def self.by_name(name)
    find_by(name: name)
  end
end
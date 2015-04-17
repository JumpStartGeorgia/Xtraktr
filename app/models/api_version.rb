class ApiVersion
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  has_many :api_methods, dependent: :destroy

  #############################

  field :permalink, type: String
  field :title, type: String, localize: true
  # whether or not can be shown to public
  field :public, type: Boolean, default: false
  # when made public
  field :public_at, type: Date

  #############################
  accepts_nested_attributes_for :api_methods, :reject_if => :all_blank, :allow_destroy => true

  attr_accessible :permalink, :title, :title_translations, :api_methods_attributes, :public, :public_at

  #############################

  # indexes
  index ({ :permalink => 1})
  index ({ :title => 1})
  index ({ :public => 1})
  index ({ :public_at => 1})

  #############################
  # Validations
  validates_presence_of :permalink
  validates_uniqueness_of :permalink
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
  before_save :set_public_at

  # if title are '', reset value to nil so fallback works
  def set_to_nil
    self.title_translations.keys.each do |key|
      self.title_translations[key] = nil if self.title_translations[key].empty?
    end
  end 

  # if public and public at not exist, set it
  # else, make nil
  def set_public_at
    if self.public? && self.public_at.nil?
      self.public_at = Time.now.to_date
    elsif !self.public?
      self.public_at = nil
    end
  end


  #############################

  def self.is_public
    where(public: true)
  end

  def self.sorted
    order_by([[:public_at, :asc], [:title, :asc]])
  end

  def self.by_permalink(permalink)
    find_by(permalink: permalink)
  end
end
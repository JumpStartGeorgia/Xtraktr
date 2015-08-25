class Country
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  #############################

  has_many :category_mappers

  #############################

  field :name, type: String, localize: true
  field :iso_num, type: String
  field :iso_alpha, type: String
  field :exclude, type: Boolean, default: false

  #############################
  attr_accessible :name, :iso_num, :iso_alpha, :name_translations

  #############################
  # indexes
  index ({ :iso_alpha => 1})
  index ({ :name => 1})

  #############################
  # permalink slug
  slug :iso_alpha

  #############################
  # Validations
  validates_presence_of :iso_num, :iso_alpha
  validate :validate_translations

  # validate the translation fields
  # name need to be validated for presence
  def validate_translations
    default_language = I18n.default_locale.to_s
    if default_language.present?
      if self.name_translations[default_language].blank?
        errors.add(:base, I18n.t('errors.messages.translation_default_lang',
            field_name: self.class.human_attribute_name('name'),
            language: Language.get_name(default_language),
            msg: I18n.t('errors.messages.blank')) )
      end
    end
  end

  #############################
  # Callbacks
 # before_save :set_to_nil

  # if name or content are '', reset value to nil so fallback works
  def set_to_nil
    self.name_translations.keys.each do |key|
      self.name_translations[key] = nil if self.name_translations[key].empty?
    end
  end

  #############################

  def self.sorted
    order_by([[:name, :asc]])
  end

  def self.not_excluded
    where(exclude: false)
  end

end

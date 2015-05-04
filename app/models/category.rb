class Category
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  has_many :category_mappers
  # belongs_to :datasets
  field :name, type: String, localize: true
  field :permalink, type: String
  field :sort_order, type: Integer, default: 1

  #############################
  attr_accessible :name, :permalink, :sort_order, :name_translations

  #############################
# "Child Protection
# Violence against children
# Disability
# Maternal and Child Health
# Education
# Social Protection
# Water, Sanitation and Hygiene
# Youth
# - copy api_method model (fields: text, premalink, sort order)
# - load icons
# - embed in datasets
# - embed in time series
# - add to home page
# - add to listing page
# - add to dashboard"


  # indexes
  index ({ :permalink => 1})
  index ({ :name => 1})
  index ({ :sort_order => 1})

  #############################
  # Validations
  validates_presence_of :permalink, :sort_order
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
    order_by([[:sort_order, :asc], [:name, :asc]])
  end

  def self.by_permalink(permalink)
    find_by(permalink: permalink)
  end
end
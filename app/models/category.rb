class Category
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  has_many :category_mappers

  #############################

  field :name, type: String, localize: true
  field :permalink, type: String
  field :sort_order, type: Integer, default: 1

  #############################
  attr_accessible :name, :permalink, :sort_order, :name_translations

  #############################
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
      self.name_translations[key] = nil if !self.name_translations[key].nil? && self.name_translations[key].empty?
    end
  end

  #############################

  def self.sorted
    order_by([[:sort_order, :asc], [:name, :asc]])
  end

  def self.by_permalink(permalink)
    find_by(permalink: permalink)
  end


  # get a list of countries that are used in datasets
  def self.in_datasets
    where(:id.in => CategoryMapper.nin(dataset_id: nil).pluck(:category_id).uniq)
  end

  # get a list of countries that are used in time series
  def self.in_time_series
    where(:id.in => CategoryMapper.nin(time_series_id: nil).pluck(:category_id).uniq)
  end

end

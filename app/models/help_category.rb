class HelpCategory
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  #############################
  attr_accessible :name,
                  :name_translations,
                  :sort_order

  #############################
  field :name, type: String, localize: true
  field :sort_order, type: Integer, default: 1
  has_many :help_category_mappers

  #############################
  index(name: 1)
  index(sort_order: 1)

  #############################
  slug :name, history: true do |help_category|
    help_category.name_translations[I18n.default_locale.to_s].to_url
  end

  #############################
  # Validations

  validates_presence_of :sort_order

  def validates_presence_of_name_for_default_language
    default_language = I18n.default_locale.to_s

    return if name_translations[default_language].present?

    errors.add(:base,
               I18n.t('errors.messages.translation_default_lang',
                      field_name: self.class.human_attribute_name('name'),
                      language: Language.get_name(default_language),
                      msg: I18n.t('errors.messages.blank')))
  end
  validate :validates_presence_of_name_for_default_language

  def self.with_name_translation(name, lang)
    where(:"name.#{lang}" => name)
  end

  def validates_uniqueness_of_name_in_all_translations
    name_translations.keys.each do |name_lang|
      next if HelpCategory
              .with_name_translation(name_translations[name_lang], name_lang)
              .not_in(_id: [id])
              .empty?

      errors.add(
        :base,
        I18n.t('errors.messages.translation_already_exists',
               model_name: I18n.t('mongoid.models.help_category.one'),
               field_name: self.class.human_attribute_name('name'),
               translation_value: name_translations[name_lang],
               language: Language.get_name(name_lang))
      )
    end
  end
  validate :validates_uniqueness_of_name_in_all_translations

  #############################
  # Callbacks

  # if name or content are '', reset value to nil so fallback works
  def set_to_nil
    name_translations.keys.each do |key|
      name_translations[key] = nil if name_translations[key].empty?
    end
  end

  before_save :set_to_nil

  #############################
  # Scopes

  def self.sorted
    order_by([[:sort_order, :asc], [:name, :asc]])
  end

  def self.used_in_help_article
    where(:id.in => HelpCategoryMapper.pluck(:help_category_id).uniq)
  end
end

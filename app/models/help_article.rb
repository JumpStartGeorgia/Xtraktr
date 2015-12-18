# Helps a site user understand XTraktr
class HelpArticle
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################
  field :title, type: String, localize: true
  index(title: 1)

  attr_accessible :title,
                  :title_translations

  def validates_presence_of_title_for_default_language
    default_language = I18n.default_locale.to_s

    return if title_translations[default_language].present?

    errors.add(:base,
               I18n.t('errors.messages.translation_default_lang',
                      field_name: self.class.human_attribute_name('title'),
                      language: Language.get_name(default_language),
                      msg: I18n.t('errors.messages.blank')))
  end
  validate :validates_presence_of_title_for_default_language

  def set_empty_title_to_nil
    title_translations.keys.each do |key|
      title_translations[key] = nil if title_translations[key].empty?
    end
  end
  before_save :set_empty_title_to_nil

  #############################
  field :article_type_id, type: Integer, default: 1
  index(article_type_id: 1)

  attr_accessible :article_type_id

  ARTICLE_TYPES = {
    how_to: 1,
    tip: 2
  }

  def article_type_symbol
    ARTICLE_TYPES.keys[ARTICLE_TYPES.values.index(article_type_id)]
  end

  def article_type
    I18n.t("mongoid.attributes.help_article.article_type_values.#{article_type_symbol}")
  end

  validates_presence_of :article_type_id
  validates :article_type_id, inclusion: { in: ARTICLE_TYPES.values }

  #############################
  field :sort_order, type: Integer, default: 1
  index(sort_order: 1)

  attr_accessible :sort_order

  validates_presence_of :sort_order

  #############################
  field :public, type: Boolean, default: false
  index(public: 1)

  attr_accessible :public

  validates_presence_of :public

  #############################
  # Scopes

  def self.sorted
    order_by([[:sort_order, :asc], [:title, :asc]])
  end

  def self.is_public
    where(public: true)
  end

  def self.by_article_type(article_type)
    desired_article_type_id = ARTICLE_TYPES[article_type]
    where(article_type_id: desired_article_type_id)
  end
end

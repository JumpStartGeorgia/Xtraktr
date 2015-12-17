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

  #############################
  field :article_type, type: Integer, default: 1
  index(article_type: 1)

  ARTICLE_TYPES = {
    how_to: 1,
    tip: 2
  }

  def article_type_name
    ARTICLE_TYPES.keys[ARTICLE_TYPES.values.index(article_type)]
  end
end

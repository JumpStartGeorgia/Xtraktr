class CustomTranslation
  require "active_model"
  include Mongoid::Callbacks

  # By default mongoid uses I18n.locale or I18n.default_locale
  # to determine which locale to use to get the localized field info.
  # This does not work when we are letting users define which locale their data is in.

  # So this class provides a method 'get_translation' that has a param to indicate which
  # locale to get data for.

  # In the model classes that inherit from this class, you have to override the GET
  # method for each field that is translated and have it call the 'get_translation' method.
  # For example:
  # def title
  #   get_translation(self.title_translations)
  # end


  ###########################################

  # save a reference to the locale that should be used to get translations for
  attr_accessor :current_locale

  ###########################################

  # when the record is initialized, set the current_locale to the primary language, or the current locale if non-set
  after_find :set_current_locale
  after_initialize :set_current_locale

  def set_current_locale
    self.current_locale = self.primary_language.present? ? self.primary_language : I18n.locale.to_s
  end

  ###########################################

  # get the translation for the provided object and locale
  # - object: reference to the mongoid field that has translations (e.g., self.title_translations)
  # - locale: what locale to get translation for; defaults to self.current_locale
  # - fallback_locale: indicates which fallback locale should be used in case the locale param does not have a translation value
  def get_translation(object, locale=self.current_locale, fallback_locale=self.primary_language)
    fallback_locale ||= I18n.default_locale

    orig_locale = I18n.locale
    I18n.locale = locale.to_sym

    logger.debug "---> for #{caller_locations(1,1)[0].label}, locale = #{I18n.locale}, fallback = #{fallback_locale}"
    text = object[I18n.locale.to_s]
    text = object[fallback_locale.to_s] if text.blank?

    I18n.locale = orig_locale

    return text
  end


end
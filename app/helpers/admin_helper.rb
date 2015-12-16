module AdminHelper
  def admin_translation_hint(model_i18n_key, field)
    t("mongoid.hints.#{model_i18n_key}.#{field}")
  end

  def admin_translation_label(model_i18n_key, field, tab_locale, default_locale_field_value='')
    label = t("mongoid.attributes.#{model_i18n_key}.#{field}")

    # As a favor to users, show the default locale's value of the field on
    # other locales (makes translation easier)
    if I18n.default_locale != tab_locale && default_locale_field_value.present?
      label << show_default_text(default_locale_field_value)
    end

    label
  end
end

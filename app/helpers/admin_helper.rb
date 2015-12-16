module AdminHelper
  def admin_translation_hint(model_i18n_key, field)
    t("mongoid.hints.#{model_i18n_key}.#{field}")
  end

  def admin_translation_label(model_i18n_key, field, tab_locale, default_locale_field_value='')
    label = t("mongoid.attributes.#{model_i18n_key}.#{field}")

    unless I18n.default_locale == tab_locale
      label << show_default_text(default_locale_field_value)
    end

    label
  end
end

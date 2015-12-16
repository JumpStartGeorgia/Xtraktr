module AdminHelper
  def admin_translation_hint(model, field)
    t("mongoid.hints.#{model.model_name.i18n_key.to_s}.#{field}")
  end

  def admin_translation_label(model_i18n_key, field, tab_locale, default_locale_field_value='')
    label = t("mongoid.attributes.#{model_i18n_key}.#{field}")
    label << default_locale_field_value unless I18n.default_locale == tab_locale
    label
  end
end

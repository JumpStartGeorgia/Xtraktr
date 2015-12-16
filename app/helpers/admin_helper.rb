module AdminHelper
  def admin_translation_hint(model, field)
    t("mongoid.hints.#{model.model_name.i18n_key.to_s}.#{field}")
  end
end

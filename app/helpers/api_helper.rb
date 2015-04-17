module ApiHelper

  # if public_at and updated_at are same dates, only show public_at, else both
  def format_api_method_dates(api_method)
    model_class = ApiMethod

    text = ''
    if api_method.public_at.present? && api_method.updated_at.present?
      if api_method.public_at == api_method.updated_at.to_date
        text << "<span>"
        text << model_class.human_attribute_name(:public_at)
        text << ": "
        text << I18n.l(api_method.public_at, format: :day_first)
        text << "</span>"
      else
        text << "<span>"
        text << model_class.human_attribute_name(:public_at)
        text << ": "
        text << I18n.l(api_method.public_at, format: :day_first)
        text << "</span>"
        text << "<span>"
        text << model_class.human_attribute_name(:updated_at)
        text << ": "
        text << I18n.l(api_method.updated_at.to_date, format: :day_first)
        text << "</span>"
      end
    end
    return text.html_safe
  end

end

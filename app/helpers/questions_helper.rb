module QuestionsHelper

  # if flag is true, show styled true
  # else, show nothing
  def format_boolean_flag(flag=false)
    if flag == true
      return "<div class='datatable-flag-highlight'>#{t('formtastic.yes')}</div>".html_safe
    end
  end

  # in the forms, show the default language text in the non-default language tabs
  # type: text, url, etc - whatever is needed to make 'tabbed_translation_form.default_xxx' work
  # IMPORTANT - html_safe must be called on the return value
  def show_default_text(text, type='text')    
    key = "tabbed_translation_form.default_#{type}"
    "<span class='default-translation-text'> (#{t(key)}: #{text})</span>"
  end

end

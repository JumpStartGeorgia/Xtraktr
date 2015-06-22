module QuestionsHelper

  # in the forms, show the default language text in the non-default language tabs
  # type: text, url, etc - whatever is needed to make 'tabbed_translation_form.default_xxx' work
  # IMPORTANT - html_safe must be called on the return value
  def show_default_text(text, type='text')    
    key = "tabbed_translation_form.default_#{type}"
    "<span class='default-translation-text'> (#{t(key)}: #{text})</span>"
  end

end

# Steps to have a tabbed form for managing translations in a model

This project requires the ability for users to pick the languages that they want to use in their records. Normally, the languages are determined by the `I18n.default_locales` but we need to be able to let users add content in languages that the site is not translated into. Yea!

This process requires the following:
* custom model class that is inherited by models with translations (localized fields)
* form have all translation fields in bootstrap tabs
* load the css and js files that drive the tabbed forms


## Custom Model Class

There is a file at `app/model/custom_translation.rb` that is the base class for all models that have localized fields. This file has the following items:
* attr_accessor 
  * current_locale - this is used to tell the model which language to use to get translations for. By default this value is either the default_language value from the inheriting model or the current I18n.locale value.
  * languages - this is an array to hold all languages that the record should use. By default it is set to the current locale. If this variable data needs to be saved, this variable should be created as a field in the inheriting model.
  * default_language - this is used to store which locale to fallback to. By default it is set to the current locale. If this variable data needs to be saved, this variable should be created as a field in the inheriting model.
* get_translation method - this method is called from the inheriting models to get the correct localized translation for a property.
* languages_sorted method - this method takes the languages list from the inheriting model and sorts it so the default_language is first


## Using the Custom Model Class
* add to attr_accessible: languages, default_language, and all fields that are translated (i.e., title_translations)



## Build the Form for Tabbed Translations
* add class `tabbed-translation-form` to the form tag
* add languages and default language select box fields
* split the non-localized fields and localized fields
* add tab code with translation fields inside the tab panels
* each form field is reference as follows:
```` ruby
          <%= f.fields_for :title_translations, OpenStruct.new(f.object.title_translations) do |translation| %>
            <%= translation.input locale, label: model_class.human_attribute_name(:title) %>
          <% end %>
````


## Load the CSS and JS files for Managing the Tabbed Forms

Simply add a call to `set_tabbed_translation_form_settings` in your controller actions to include the css and js files necessary for the tabbed forms. This method is located in the `application_controller`.



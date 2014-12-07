# Steps to have a tabbed form for managing translations in a model

This project requires the ability for users to pick the languages that they want to use in their records. Normally, the languages for localization in mongoid are determined by the `I18n.default_locales` but we need to be able to let users add content in languages that the site is not translated into. Yeah!

This process requires the following:
* custom model class that is inherited by models with translations (localized fields)
* form with all translation fields in bootstrap tabs
* css and js files that drive the tabbed forms


## Custom Model Class

There is a file at `app/model/custom_translation.rb` that is the base class for all models that have localized fields. This file has the following items:
* attr_accessor 
  * `current_locale` - this is used to tell the model which language to use to get translations for. By default this value is either the default_language value from the inheriting model or the current I18n.locale value.
  * `languages` - this is an array to hold all languages that the record should use. By default it is set to the current locale. If this variable data needs to be saved, this variable should be created as a field in the inheriting model.
  * `default_language` - this is used to store which locale to fallback to. By default it is set to the current locale. If this variable data needs to be saved, this variable should be created as a field in the inheriting model.
* `get_translation` - this method is called from the inheriting models to get the correct localized translation for a property.
* `languages_sorted` - this method takes the languages array from the inheriting model and sorts it so the default_language is first


## Using the Custom Model Class
* inherit the class: `class Shapeset < CustomTranslation`
* make the fields localized: `field :title, type: String, localize: true`
* add to `attr_accessible`: languages, default_language, and all fields that are translated (i.e., title_translations)
* validation: 
  * `validates_presence_of :default_language`
  * `validate :validate_languages` - make sure at least one language is provided
  ```` ruby 
  # validate that at least one item in languages exists
  def validate_languages
        # first remove any empty items
        self.languages.delete("")
        if self.languages.blank?
          errors.add(:languages, I18n.t('errors.messages.blank'))
        end
  end
  ````
  * `validate :validate_translations` - validate that the default_language has the required fields
  ```` ruby 
  # validate the translation fields
  # title and source need to be validated for presence
  def validate_translations
        if self.default_language.present?
          if self.title_translations[self.default_language].blank?
            errors.add(:base, I18n.t('errors.messages.translation_default_lang', 
                field_name: self.class.human_attribute_name('title'),
                language: Language.get_name(self.default_language),
                msg: I18n.t('errors.messages.blank')) )
          end
          if self.source_translations[self.default_language].blank?
            errors.add(:base, I18n.t('errors.messages.translation_default_lang', 
                field_name: self.class.human_attribute_name('source'),
                language: Language.get_name(self.default_language),
                msg: I18n.t('errors.messages.blank')) )
          end
        end
  end 
  ````
  * validate non-required translation fields, e.g., urls
  (`validate :validate_url`)
  ```` ruby 
  # have to do custom url validation because validate format with does not work on localized fields
  def validate_url
        self.source_url_translations.keys.each do |key|
          if self.source_url_translations[key].present? && (self.source_url_translations[key] =~ URI::regexp(['http','https'])).nil?
            errors.add(:base, I18n.t('errors.messages.translation_any_lang', 
                field_name: self.class.human_attribute_name('source_url'),
                language: Language.get_name(key),
                msg: I18n.t('errors.messages.invalid')) )
            return
          end
        end
  end
  ````
* override the get methods for the fields that are localized to call the `get_translations` method in the inherited class:
  ```` ruby 
  def title
    get_translation(self.title_translations)
  end
  ````
* update anywhere else in the model that sets the value of a localized field to use the translations verison:
  ```` ruby 
  self.names_translations[locale] = 'this is a title'
  ````



## Build the Form for Tabbed Translations

* add class `tabbed-translation-form` to the form tag
* add languages and default language select box fields
* split the non-localized fields and localized fields
* add tab code with translation fields inside the tab panels
* each form field should be coded as follows:
```` ruby
  <%= f.fields_for :title_translations, OpenStruct.new(f.object.title_translations) do |translation| %>
    <%= translation.input locale, label: model_class.human_attribute_name(:title) %>
  <% end %>
  <%= f.fields_for :source_translations, OpenStruct.new(f.object.source_translations) do |translation| %>
    <%= translation.input locale, label: model_class.human_attribute_name(:source) %>
  <% end %>
  ...
````


## Load the CSS and JS files for Managing the Tabbed Forms

Simply add a call to `set_tabbed_translation_form_settings` in your controller actions (new, edit, create error, edit erorr) to include the css and js files necessary for the tabbed forms. This method is located in the `application_controller`.



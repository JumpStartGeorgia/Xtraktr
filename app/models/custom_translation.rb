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


  # ###########################################
  # # if the object has translations but is an embeded document, it should not be using callbacks
  # # so set this to false if you do not want callbacks working
  # def initialize(options={use_callbacks: true})
  #   @use_callbacks = use_callbacks
  #   puts "--> initialize, use_callbacks = #{use_callbacks}"
  # end

  ###########################################

  # current_locale: save a reference to the locale that should be used to get translations for
  # languages: optional variable array to hold list of required locales that should be overriden with a field in the inheriting class
  # default_language: optional variable to hold default locale that should be overriden with a field in the inheriting class
  attr_accessor :current_locale, :languages, :default_language

  ###########################################

  # when the record is initialized, set the current_locale to the default language, or the current locale if non-set
  after_initialize :set_current_locale
  after_initialize :set_languages


  # if the current locale is in the list of languages or there is no default language, use current locale, else default to default language
  def set_current_locale
#    puts "--> setting current locale"
    self.current_locale = ((self.languages.present? && self.languages.include?(I18n.locale.to_s)) || self.default_language.blank?) ? I18n.locale.to_s : self.default_language
#    puts "--> self.current_locale = #{self.current_locale}"
  end

  # if this is a new record and languages does not exist, initialize it to the current locale
  def set_languages
#    puts "--> setting languages"
    self.languages = [I18n.locale.to_s] if self.languages.blank?
    self.default_language = I18n.locale.to_s if self.default_language.blank?
#    puts "--> self.languages = #{self.languages}"
  end

  ###########################################

  # get the translation for the provided object and locale
  # - object: reference to the mongoid field that has translations (e.g., self.title_translations)
  # - locale: what locale to get translation for; defaults to self.current_locale
  # - fallback_locale: indicates which fallback locale should be used in case the locale param does not have a translation value
  def get_translation(object, locale=self.current_locale, fallback_locale=self.default_language)
    fallback_locale ||= I18n.default_locale

    orig_locale = I18n.locale
    I18n.locale = locale.to_sym

    # puts "---> for #{caller_locations(1,1)[0].label}, locale = #{I18n.locale}, fallback = #{fallback_locale}"
    text = object[I18n.locale.to_s]
    text = object[fallback_locale.to_s] if text.blank?

    I18n.locale = orig_locale

    return text
  end


  # get the languages sorted with default first
  def languages_sorted
    langs = self.languages.dup
    if self.default_language.present?
      langs.rotate!(langs.index(self.default_language))
    end
    langs
  end

  # return array of language objects for each locale in languages
  def language_objects
    langs = []

    if self.languages.present?
      self.languages_sorted.each do |locale|
        l = Language.where(:locale => locale).to_a

        if l.present?
          langs << l.first
        end
      end
    end

    return langs
  end


  # strip the string and fix any bad characters
  # some text is in microsoft ansi encoding and needs to be fixed
  # reference: https://msdn.microsoft.com/en-us/library/cc195054.aspx
  def clean_string(str)
    if str.class == String && str.present?
      clean_text(str)
      # str
      # clean_str = clean_text(str)
      # if clean_str.present?
      #   clean_str.gsub(/\\x../) {|s| [s[2..-1].hex].pack("C")}.force_encoding("UTF-8").strip.chomp
      # else
      #   str
      # end
    else
      str
    end
  end

  # strip the string and fix any bad characters
  # some text is in microsoft ansi encoding and needs to be fixed
  # reference: https://msdn.microsoft.com/en-us/library/cc195054.aspx
  # - <91> = ‘
  # - <92> = ’
  # - <93> = “
  # - <94> = ”
  # - <96> = —
  # - <97> = —
  # - \xa0 = space
  # if string = '' or '\\N' return nil
  def clean_text(str, options={})
    options[:format_code] = false if options[:format_code].nil?
    single_quote = "'"
    double_quote = '"'
    dash = "-"
    space = " "

    if !str.nil? && str.length > 0
      x = str.dup.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')

      if options[:format_code] == true
        x.gsub!('.', '|')
        x.downcase!
      end

      y = x.gsub("<91>", single_quote).gsub("\\x91", single_quote)
            .gsub("<92>", single_quote).gsub("\\x92", single_quote)
            .gsub("<93>", double_quote).gsub("\\x93", double_quote)
            .gsub("<94>", double_quote).gsub("\\x94", double_quote)
            .gsub("<96>", dash).gsub("\\x96", dash)
            .gsub("<97>", dash).gsub("\\x97", dash)
            .gsub("\\xa0", space).chomp.strip

      y = nil if y.empty? || y == "\\N"
      return y
    else
      return str
    end
  end
end

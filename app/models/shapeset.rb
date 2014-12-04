class Shapeset < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  #############################

  belongs_to :user

  #############################
  # paperclip data file storage
  has_mongoid_attached_file :shapefile, :url => "/system/shapesets/:id/original/:filename", :use_timestamp => false

  field :title, type: String, localize: true
  field :description, type: String, localize: true
  field :source, type: String, localize: true
  field :source_url, type: String, localize: true
  field :names, type: Array, default: [], localize: true
  field :languages, type: Array
  field :default_language, type: String

  #############################
  # indexes
  index ({ :title => 1})
  index ({ :user_id => 1})

  #############################
  
  attr_accessible :title, :description, :shapefile, :names, :user_id, :source, :source_url, :languages, :default_language,
    :title_translations, :description_translations, :source_translations, :source_url_translations

  KEY_NAME = 'name_'

  #############################
  # Validations
  validates_presence_of :languages
  validates_attachment :shapefile, :presence => true, 
      :content_type => { :content_type => ["text/plain", "application/json", "application/octet-stream"] }
  validates_attachment_file_name :shapefile, :matches => [/geojson\Z/, /json\Z/]
  validate :validate_url
  validate :validate_languages
  validate :validate_translations

  # validate that at least one item in languages exists
  def validate_languages
    # first remove any empty items
    self.languages.delete("")
    logger.debug "***** validates languages: #{self.languages.blank?}"
    if self.languages.blank?
      errors.add(:languages, I18n.t('errors.messages.blank'))
    end
  end

  # validate the translation fields
  # only primary language field needs to be validated for presence
  def validate_translations
    logger.debug "***** validates translations"
    if self.default_language.present?
      logger.debug "***** - primary is present; title = #{self.title_translations[self.default_language]}; source = #{self.source_translations[self.default_language]}"
      if self.title_translations[self.default_language].blank?
        Title of the primary language english cannot be blank

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

  #############################

  before_create :process_file

  # process the shapefile
  def process_file
    file_to_process = self.shapefile.queued_for_write[:original].path
    if File.exists? file_to_process
      json = JSON.parse(File.read(file_to_process))
      if json.present?
        # get the keys for the properties
        keys = json['features'].first['properties'].keys.select{|x| x.match(/name_?/)}
        if keys.present?
          locales = keys.map{|x| x.gsub(KEY_NAME, '')}
          locales.each do |locale|
            self.names_translations[locale] = json['features'].map{|x| x['properties'][KEY_NAME + locale]}
          end
        end
      end
    end
  end

  #############################

  def self.sorted
    order_by([[:title, :asc]])
  end

  # get url to file
  def self.get_url(shapeset_id)
    find_by(id: shapeset_id).shapefile.url
  end

  #############################

  # read in the geojson from the file
  def get_geojson
    path = "#{Rails.root}/public#{self.shapefile.url}"
    geojson = nil
    if File.exists?(path)
      geojson = File.read(path)
    end

    return JSON.parse(geojson)
  end


  # get the languages sorted with primary first
  def languages_sorted
    langs = self.languages.dup
    if self.default_language.present?
      langs.rotate!(langs.index(self.default_language))
    end
    langs
  end

  #############################
  ## override get methods for fields that are localized
  def title
    get_translation(self.title_translations)
  end
  def description
    get_translation(self.description_translations)
  end
  def source
    get_translation(self.source_translations)
  end
  def source_url
    get_translation(self.source_url_translations)
  end
end

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
  field :names, type: Array, localize: true
  field :languages, type: Array
  field :default_language, type: String

  #############################
  # indexes
  index ({ :title => 1})
  index ({ :user_id => 1})

  #############################
  
  attr_accessible :title, :description, :shapefile, :names, :user_id, :source, :source_url, 
    :languages, :default_language,
    :title_translations, :description_translations, :source_translations, :source_url_translations
  attr_accessor :reset_dataset_files, :orig_source, :orig_source_url
  KEY_NAME = 'name_'

  #############################
  # Validations
  validates_presence_of :default_language
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
    else
      # make sure each locale in languages is in Language
      self.languages.each do |locale|
        if Language.where(:locale => locale).count == 0
          errors.add(:languages, I18n.t('errors.messages.invalid_language', lang_locale: locale))
        end
      end
    end
  end

  # validate the translation fields
  # title and source need to be validated for presence
  def validate_translations
    logger.debug "***** validates translations"
    if self.default_language.present?
      logger.debug "***** - default is present; title = #{self.title_translations[self.default_language]}; source = #{self.source_translations[self.default_language]}"
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
      if self.source_url_translations[self.default_language].blank?
        errors.add(:base, I18n.t('errors.messages.translation_default_lang', 
            field_name: self.class.human_attribute_name('source_url'),
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
  ## Callbacks

  # before_create :process_file
  after_initialize :set_orig_values
  after_find :set_orig_values
  before_post_process :process_file
  after_post_process :set_update_datasets
  after_save :check_source_changes
  after_commit :update_datasets

  # set original source values so can check if source changed
  def set_orig_values
    if self.default_language.present?
      self.orig_source = self.source_translations[default_language] if self.source_translations.present? && self.source_translations[default_language].present?
      self.orig_source_url = self.source_url_translations[default_language] if self.source_url_translations.present? && self.source_url_translations[default_language].present?
    end
  end

  # process the shapefile
  def process_file
    logger.debug "$$$$$$$$ new shapefile so getting name of each shape"
    file_to_process = self.shapefile.queued_for_write[:original].path
    if File.exists? file_to_process
      json = JSON.parse(File.read(file_to_process))
      if json.present?
        # get the names of the shapes
        keys = json['features'].first['properties'].keys.select{|x| x.match(/name_?/)}
        if keys.present?
          locales = keys.map{|x| x.gsub(KEY_NAME, '')}
          locales.each do |locale|
            self.names_translations[locale] = json['features'].map{|x| x['properties'][KEY_NAME + locale]}
          end
        end
      end
    end
    return true
  end

  # if the source changed, update the json file values
  # - the source and source url are shown in the credits of the map if these two json keys are present
  #   - this happens in the highmaps.js code itself
  def check_source_changes
    logger.debug "@@@@@@@@@@@@@ check_source_changes"
    if self.orig_source != self.source_translations[self.default_language] || self.orig_source_url != self.source_url_translations[self.default_language] && File.exists?(self.shapefile.url)
      logger.debug "@@@@@@@@@@@@@ changed! updating file!"

      file = "#{Rails.public_path}#{self.shapefile.url}"

      json = JSON.parse(File.read(file))
      # set the source and source url in the file
      json['copyrightShort'] = self.source_translations[self.default_language]
      json['copyrightUrl'] = self.source_url_translations[self.default_language]

      File.open(file, 'w') do |f|
        f << json.to_json
      end

      # make sure all datasets using this file is updated too
      self.reset_dataset_files = true
    end
    return true
  end        

  # if the shapeset changed, set flag so dataset json will be updated
  def set_update_datasets
    logger.debug "$$$$$$$ shape file changed, setting flag"
    self.reset_dataset_files = true

    return true
  end

  # if the shapeset changed, update the datasets that use this shapeset
  # have to do it after commit to make sure the new shapefile has been written to disk first
  def update_datasets
    if self.reset_dataset_files == true
      logger.debug "$$$$$$$ shape file changed, so need to update datasets"
      Dataset.with_shapeset(self.id).each do |dataset|
        dataset.update_mappable_flag
      end
    end

    return true
  end

  #############################
  ## Scopes

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
    path = "#{Rails.public_path}/#{self.shapefile.url}"
    geojson = nil
    if File.exists?(path)
      geojson = File.read(path)
    end

    return JSON.parse(geojson)
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

  #############################

  def title_with_source
    "#{self.title} (#{self.source})"
  end

end

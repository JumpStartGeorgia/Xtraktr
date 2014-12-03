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
  field :primary_language, type: String

  #############################
  # indexes
  index ({ :title => 1})
  index ({ :user_id => 1})

  #############################
  # Validations
  validates_presence_of :title, :source#, :primary_language, :languages
  validates_attachment :shapefile, :presence => true, 
      :content_type => { :content_type => ["text/plain", "application/json", "application/octet-stream"] }
  validates_attachment_file_name :shapefile, :matches => [/geojson\Z/, /json\Z/]
  validate :url_validation

  # have to do custom url validation because validate format with does not work on localized fields
  def url_validation
    self.source_url_translations.keys.each do |key|
      if self.source_url_translations[key].present? && (self.source_url_translations[key] =~ URI::regexp(['http','https'])).nil?
        errors.add(:source_url, I18n.t('errors.messages.invalid'))
        return
      end
    end
  end

  #############################
  
  attr_accessible :title, :description, :shapefile, :names, :user_id, :source, :source_url, :languages, :primary_language

  KEY_NAME = 'name_'

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

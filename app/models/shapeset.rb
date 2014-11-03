class Shapeset
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  #############################

  belongs_to :user

  #############################
  # paperclip data file storage
  has_mongoid_attached_file :shapefile, :url => "/system/shapesets/:id/original/:filename", :use_timestamp => false

  field :title, type: String
  field :description, type: String
  # hold the names of the shapes for each locale
  # format: {en: [name1, name2, ], ka: [name1, name2, ]}
  field :names, type: Array, localize: true

  #############################
  # indexes
  index ({ :title => 1})
  index ({ :user_id => 1})

  #############################
  # Validations
  validates_presence_of :title
  validates_attachment :shapefile, :presence => true, 
      :content_type => { :content_type => ["text/plain", "application/json", "application/octet-stream"] }
  validates_attachment_file_name :shapefile, :matches => [/geojson\Z/, /json\Z/]

  #############################
  
  attr_accessible :title, :description, :shapefile, :names, :user_id

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
          self.names = {}
          locales.each do |locale|
            self.names[locale] = json['features'].map{|x| x['properties'][KEY_NAME + locale]}
          end
        end
      end
    end
  end

  #############################

  def self.sorted
    order_by([[:title, :asc]])
  end

  # only get title and description
  def self.basic_info
    only(:_id, :title, :description)
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

end

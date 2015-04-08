class Report
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  #############################

  belongs_to :language
  belongs_to :dataset


  #############################
  has_mongoid_attached_file :file, url: "/system/datasets/:dataset_id/reports/:id/:filename", use_timestamp: false


  field :title, type: String
  field :summary, type: String
  field :released_at, type: Date
  # record the extension of the file
  field :file_extension, type: String


  #############################
  attr_accessible :file, :title, :summary, :released_at, :language_id

  #############################
  # Validations
  validates_presence_of :title, :released_at, :language_id
  validates_attachment :file, 
      :content_type => { :content_type => ["text/plain", "application/pdf", "application/vnd.oasis.opendocument.text", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/msword"] }
  validates_attachment_file_name :file, :matches => [/txt\Z/i, /pdf\Z/i, /odt\Z/i, /doc?x\Z/i]


  #############################
  # Callbacks
  before_save :get_file_extension

  # if file extension does not exist, get it
  def get_file_extension
    logger.debug "%%%%%%%%%%%%%%%% file extension = #{File.extname(self.file.url).gsub('.', '').downcase}"
    self.file_extension = File.extname(self.file.url).gsub('.', '').downcase if self.file_extension.blank?
  end

  #############################
  # Scopes

  def sorted
    order_by([[:released_at, :desc], [:title, :asc]])
  end

  #############################

  # indicate the file type based off of the file extension
  def file_type
    case self.file_extension
    when 'pdf'
      'PDF'
    when 'doc', 'docx'
      'DOC'
    when 'odt'
      'ODT'
    when 'txt'
      'TXT'
    else
      ''
    end
  end


end
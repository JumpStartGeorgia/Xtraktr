class PageContent
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  field :name, type: String
  field :title, type: String, localize: true
  field :content, type: String, localize: true

  #############################

  # indexes
  index ({ :name => 1})

  #############################
  # Validations
  validates_presence_of :name, :title
  validates_uniqueness_of :name

  #############################

  def self.by_name(name)
    find_by(name: name)
  end
end
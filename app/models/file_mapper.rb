class FileMapper
  include Mongoid::Document
  include Mongoid::Timestamps


  #############################

   field :key, type: String
   field :file, type: String

  #############################
  ## Indexes

  index({ :key => 1}, { background: true})
  index({ :user_id => 1}, { background: true})

  attr_accessible :key, :file

  before_create :create_key

  def create_key
    begin
      self.key = SecureRandom.base64.tr('+/=', 'dTv')
    end while self.class.where(key: self.key).any?
  end
end





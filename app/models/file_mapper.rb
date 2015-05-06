class FileMapper
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

   field :key, type: String, default: ->{ 
      begin
         key = SecureRandom.base64.tr('+/=', 'dTv')
      end while self.class.where(key: key).any?
      key
   }
   field :file, type: String
   field :file_type, type: String

  #############################
  ## Indexes

  index({ :key => 1}, { background: true})
  index({ :user_id => 1}, { background: true})

  attr_accessible :key, :file, :file_type

end





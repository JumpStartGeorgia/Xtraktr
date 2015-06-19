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
   field :dataset_id, type: String
   field :dataset_type, type: String
   field :dataset_locale, type: String
   field :download_type, type: String

  #############################
  ## Indexes

  index({ :key => 1}, { background: true})
  index({ :dataset_id => 1}, { background: true})
  index({ :dataset_locale => 1}, { background: true})

  attr_accessible :key, :dataset_id, :dataset_type, :dataset_locale, :download_type

end





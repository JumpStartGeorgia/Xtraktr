class ApiKey
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  belongs_to :user
  has_many :api_requests

  #############################

  field :key, :type => String

  #############################
  ## Indexes

  index({ :key => 1}, { background: true})
  index({ :user_id => 1}, { background: true})

  ####################
  ## Callbacks

  before_create :create_key

  def create_key
    begin
      self.key = SecureRandom.base64.tr('+/=', 'dTv')
    end while self.class.where(key: self.key).any?
  end


  ####################

end
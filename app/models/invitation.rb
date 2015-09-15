class Invitation
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  belongs_to :from_user, foreign_key: :from_user_id, class_name: "User"
  belongs_to :to_user, foreign_key: :to_user_id, class_name: "User"

  #############################

  field :key, :type => String
  field :to_email, :type => String
  field :sent_at, :type => DateTime
  field :accepted_at, :type => DateTime
  field :message, :type => String

  #############################

  attr_accessible :from_user_id, :key, :to_email, :to_user_id, :sent_at, :accepted_at, :message
	attr_accessor :send_notification

  #############################
  ## Indexes

  index({ :key => 1}, { background: true})
  index({ :to_user_id => 1}, { background: true})
  index({ :from_user_id => 1}, { background: true})
  index({ :accepted_at => 1}, { background: true})

  #############################
  ## Validations

  validates :from_user_id, :to_email, :presence => true
  validates_format_of :to_email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i

  ####################
  ## Callbacks
  before_create :create_default_values

  def create_default_values
    begin
      self.key = SecureRandom.base64.tr('+/=', 'dTv')
    end while self.class.where(key: self.key).any?

    self.sent_at = Time.now
    return true
  end

  ####################
  ## Scopes

  def self.find_by_key(to_user_id, key)
    where(to_user_id: to_user_id, key: key).first
  end

  def self.delete_accepted_invitation(from_user_id, to_user_id)
    where(from_user_id: from_user_id, to_user_id: to_user_id, :accepted_at.ne => nil).destroy_all
  end

  # get list of pending invidations from a user id
  def self.pending_from_user(from_user_id)
    where(from_user_id: from_user_id, accepted_at: nil)
  end

  # get list of pending invidations to a user id
  def self.pending_to_user(to_user_id)
    where(to_user_id: to_user_id, accepted_at: nil)
  end

  def self.already_exists?(from_user_id, to_email)
    where(from_user_id: from_user_id, to_email: to_email).count > 0
  end


end

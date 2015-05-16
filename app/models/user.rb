class User
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Confirmable
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time
  include Mongoid::Timestamps

  #############################

  has_many :datasets
  has_many :api_keys, dependent: :destroy
  accepts_nested_attributes_for :api_keys, :reject_if => :all_blank, :allow_destroy => true

  #############################

  ROLES = {:user => 0, :data_editor => 33, :site_admin => 75, :admin => 99}

  #############################

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, 
         :omniauthable, :omniauth_providers => [:facebook]

  ## Constants
  AGE_GROUP = { 1 => '17-24', 2 => '25-34', 3 => '35-44', 4 => '45-54', 5 => '55-64', 6 => 'above'}
  STATUS = { 1 => 'researcher',
             2 => 'student',
             3 => 'journalist',
             4 => 'ngo',
             5 => 'government_official',
             6 => 'international_organization',
             7 => 'private_sector',
             8 => 'other' }

  ## Database authenticatable
  field :email,              :type => String, :default => ""
  field :encrypted_password, :type => String, :default => ""

  ## Recoverable
  field :reset_password_token,   :type => String
  field :reset_password_sent_at, :type => Time

  ## Rememberable
  field :remember_created_at, :type => Time

  ## Trackable
  field :sign_in_count,      :type => Integer, :default => 0
  field :current_sign_in_at, :type => Time
  field :last_sign_in_at,    :type => Time
  field :current_sign_in_ip, :type => String
  field :last_sign_in_ip,    :type => String

  ## user info
  field :first_name, type: String
  field :last_name, type: String
  field :age_group, type: Integer #{ 1 => '17-24', 2 => '25-34', 3 => '35-44', 4 => '45-54', 5 => '55-64', 6 => 'above'}
  field :residence, type: String
  field :affiliation, type: String
  field :status, type: Integer #{ 1 => 'researcher', 2 => 'student', 3 => 'journalist', 4 => 'ngo', 5 => 'government_official', 6 => 'international_organization', 7 => 'private_sector', 8 => 'other' } 
  field :status_other, type: String
  field :description, type: String
  field :terms, type: Boolean, default: false
  field :notifications, type: Boolean, default: false
  field :notification_locale, type: String, default: I18n.default_locale.to_s


  ## Encryptable
  # field :password_salt, :type => String

  ## Confirmable
  # field :confirmation_token,   :type => String
  # field :confirmed_at,         :type => Time
  # field :confirmation_sent_at, :type => Time
  # field :unconfirmed_email,    :type => String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, :type => Integer, :default => 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    :type => String # Only if unlock strategy is :email or :both
  # field :locked_at,       :type => Time

  ## Token authenticatable
  # field :authentication_token, :type => String

  ## Roles
  field :role,  :type => Integer, :default => 0

  ## Omniauth fields
  field :provider,  :type => String
  field :uid,  :type => String
  field :nickname,  :type => String
  field :avatar,  :type => String  

  #############################

  # indexes
  index({ :email => 1}, { background: true})
  index({ :role => 1}, {background: true})
  index({ :provider => 1, :role => 1}, {background: true})
  index({ :reset_password_token => 1}, { background: true, unique: true, sparse: true })

  #############################
  attr_accessor :account
  attr_accessible :email, :password, :password_confirmation, :remember_me, 
                  :role, :provider, :uid, :nickname, :avatar,
                  :first_name, :last_name, :age_group, :residence,
                  :affiliation, :status, :status_other, :description, :terms, :account, 
                  :notifications, :notification_locale, :api_keys_attributes

  #############################
  ## Validations

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :age_group, inclusion: { in: AGE_GROUP.keys }
  validates :residence, presence: true
  validates :email, presence: true
  validates :affiliation, presence: true
  validates :status, inclusion: { in: STATUS.keys }
  validates_presence_of :status_other, :if => lambda { |o| o.status == 8 }
  validates :account, :numericality => { :equal_to => 1 }
  validates :terms, :inclusion => {:in => [true]  }
  ####################

  before_create :create_nickname

  def create_nickname
    self.nickname = self.email.split('@')[0] if self.nickname.blank? && self.email.present?

    return true
  end

  #############################

  def name
    if self.first_name.present?
      if self.last_name.present?
        "#{self.first_name} #{self.last_name}"
      else
        self.first_name
      end
    else
      self.nickname
    end
  end


  def self.no_admins
    where("role != ?", ROLES[:admin])
  end

  # if no role is supplied, default to the basic user role
  def check_for_role
    self.role = ROLES[:user] if self.role.nil?
  end

  # use role inheritence
  # - a role with a larger number can do everything that smaller numbers can do
  def role?(base_role)
    if base_role && ROLES.values.index(base_role)
      return base_role <= self.role
    end
    return false
  end
  
  def role_name
    ROLES.keys[ROLES.values.index(self.role)].to_s
  end

  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    logger.debug "+++++++++++++ #{auth.inspect}"
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      user = User.create(  nickname: auth.info.nickname,
                           provider: auth.provider,
                           uid: auth.uid,
                           email: auth.info.email.present? ? auth.info.email : "<%= Devise.friendly_token[0,10] %>@fake.com",
                           avatar: auth.info.image,
                           password: Devise.friendly_token[0,20]
                           )
    end
    user
  end

  # if login fails with omniauth, sessions values are populated with
  # any data that is returned from omniauth
  # this helps load them into the new user registration url
  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"]# && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end
  
  # if user logged in with omniauth, password is not required
  def password_required?
    super && provider.blank?
  end

  def agreement(dataset_id, dataset_type, dataset_locale)
    a = Agreement.create({
        email: self.email,
        first_name: self.first_name,
        last_name: self.last_name,
        age_group: self.age_group,
        residence: self.residence,
        affiliation: self.affiliation,
        status: self.status,
        status_other: self.status_other,
        description: self.description,
        dataset_id: Moped::BSON::ObjectId.from_string(dataset_id),
        dataset_type: dataset_type,
        dataset_locale: dataset_locale,
        terms: self.terms
      })
    a.valid?
  end
  # def to_json(opts={})  
  #   opts.merge!(:only => [:email])
  #   super(opts)
  # end
end

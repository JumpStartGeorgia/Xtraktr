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
  field :notifications, type: Boolean, default: true
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
  attr_accessor #:account, :facebook_account, :direct
  attr_accessible :email, :password, :password_confirmation, :remember_me,
                  :role, :provider, :uid, :nickname, :avatar,
                  :first_name, :last_name, :age_group, :residence,
                  :affiliation, :status, :status_other, :description, #:account, :facebook_account,
                  :notifications, :notification_locale, :api_keys_attributes#, :direct

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
 # validates :account, :numericality => { :equal_to => 1 } #, :if => lambda { |o| o.account.present? }
  #validates :facebook_account, :inclusion => { :in => ["0", "1"] } #, :if => lambda { |o| o.is_registration.present? }  
  #validates :direct, :inclusion => { :in => ["0", "1"] }
  ####################
  ## Callbacks

  before_create :create_nickname
  # before_validation :test
  # def test
  #   logger.debug "@@@@@@@@@@@ reset_password_period_valid = #{self.reset_password_period_valid?}"
  #   return true
  # end
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
    ne(role: ROLES[:admin])
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

  def self.find_for_facebook_oauth(auth, params) #, signed_in_resource=nil
    user = where(provider: auth.provider, uid: auth.uid).first_or_initialize do |user|
      user.nickname = auth.info.nickname if auth.info.has_key?("nickname")
      user.first_name = (params["first_name"].present? ? params["first_name"] : auth.info.first_name) if params["first_name"].present? || auth.info["first_name"].present?
      user.last_name = (params["last_name"].present? ? params["last_name"] : auth.info["last_name"]) if params["last_name"].present? || auth.info["last_name"].present?
      user.email = (params["email"].present? ? params["email"] : (auth.info["email"].present? ? auth.info["email"] : "<%= Devise.friendly_token[0,10] %>@fake.com"))
      user.affiliation = params["affiliation"] if params["affiliation"].present?
      user.age_group = params["age_group"] if params["age_group"].present?
      user.residence = params["residence"] if params["residence"].present?
      user.status = params["status"] if params["status"].present?
      user.status_other = params["status_other"] if params["status_other"].present?
      user.description = params["description"] if params["description"].present?
      user.avatar = auth.info.image
      user.password = Devise.friendly_token[0,20]
      user.notifications = params["notifications"] == "1" if params["notifications"].present?
      user.notification_locale = params["notification_locale"] if params["notification_locale"].present?
    end

    user.save(validate: false)
    user
    # logger.debug "+++++++++++++ #{auth.inspect}"
    # user = User.where(:provider => auth.provider, :uid => auth.uid).first
    # unless user
    #   user = User.create(  nickname: auth.info.nickname,
    #                        provider: auth.provider,
    #                        uid: auth.uid,
    #                        email: auth.info.email.present? ? auth.info.email : "<%= Devise.friendly_token[0,10] %>@fake.com",
    #                        avatar: auth.info.image,
    #                        password: Devise.friendly_token[0,20]
    #                        )
    # end
    # user
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
    super && provider.blank? # provider.blank?
  end

  def agreement(dataset_id, dataset_type, dataset_locale, download_type)
    a = Agreement.create({
        email: self.email,
        first_name: self.first_name,
        last_name: self.last_name,
        age_group: self.age_group,
        residence: Country.find(self.residence).name,
        affiliation: self.affiliation,
        status: self.status,
        status_other: self.status_other,
        description: self.description,
        dataset_id: Moped::BSON::ObjectId.from_string(dataset_id),
        dataset_type: dataset_type,
        dataset_locale: dataset_locale,        
        download_type: download_type
      })
    a.valid?
  end
  # def to_json(opts={})
  #   opts.merge!(:only => [:email])
  #   super(opts)
  # end
end

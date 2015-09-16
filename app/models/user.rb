class User
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  #############################

  has_many :datasets
  has_many :api_keys, dependent: :destroy
  has_many :members, class_name: 'UserMember', inverse_of: :group, dependent: :destroy
  has_many :groups, class_name: 'UserMember', inverse_of: :member, dependent: :destroy do

    # determine if user is in group
    def in_group?(group_id)
      where(group_id: group_id).count > 0
    end

  end

  accepts_nested_attributes_for :api_keys, :reject_if => :all_blank, :allow_destroy => true
  accepts_nested_attributes_for :members
  accepts_nested_attributes_for :groups

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


  ## user info
  field :is_user, type: Boolean, default: true
  field :email_no_domain, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :age_group, type: Integer #{ 1 => '17-24', 2 => '25-34', 3 => '35-44', 4 => '45-54', 5 => '55-64', 6 => 'above'}
  field :residence, type: String
  field :affiliation, type: String
  field :status, type: Integer #{ 1 => 'researcher', 2 => 'student', 3 => 'journalist', 4 => 'ngo', 5 => 'government_official', 6 => 'international_organization', 7 => 'private_sector', 8 => 'other' }
  field :status_other, type: String
  field :description, type: String
  field :phone, type: String
  field :website_url, type: String
  field :notifications, type: Boolean, default: true
  field :notification_locale, type: String, default: I18n.default_locale.to_s

  field :permalink, type: String

  ## Roles
  field :role,  :type => Integer, :default => 0

  ## Omniauth fields
  field :provider,  :type => String
  field :uid,  :type => String
  field :nickname,  :type => String
  field :avatar,  :type => String

  #############################
  # paperclip user icon
  has_mongoid_attached_file :avatar,
              :url => "/system/avatars/:id/:style.:extension",
              :styles => {
                :'thumb' => {:geometry => "160x160>"},
                :'small' => {:geometry => "40x40>"}
              },
              :convert_options => {
                :'thumb' => "-quality 75 -strip",
                :'small' => "-quality 75 -strip"
              },
              :default_url => "/assets/missing/avatar/:style_avatar.png"

  #############################

  # indexes
  index({ :is_user => 1, :email => 1}, { background: true})
  index({ :role => 1}, {background: true})
  index({ :provider => 1, :role => 1}, {background: true})
  index({ :reset_password_token => 1}, { background: true, unique: true, sparse: true })
  index({ :email_no_domain => 1, :role => 1}, {background: true})

  #############################
  # permalink slug
  # - words that the slug cannot be
  SLUG_RESERVE = ['new', 'edit', 'delete', 'update', 'create', 'destroy', 'show', 'index', 'admin', 'root', 'omniauth', 'locale', 'api', 'embed', 'highlights', 'contact', 'download', 'download_request', 'instructions', 'about', 'generate_highlights', 'datasets', 'groups', 'weights', 'time_series', 'questions', 'answers', 'settings', 'manage_datasets', 'manage_time_series', 'accept_invitation_from_notification']
  slug :permalink, history: true, reserve: SLUG_RESERVE do |user|
    user.permalink.to_url
  end

  #############################
  attr_accessor :account, :facebook_account, :is_registration
  attr_accessible :email, :password, :password_confirmation, :remember_me,
                  :role, :provider, :uid, :nickname, :avatar, :permalink,
                  :first_name, :last_name, :age_group, :residence,
                  :affiliation, :status, :status_other, :description, :account, :facebook_account,
                  :phone, :website_url, :is_user, :avatar,
                  :notifications, :notification_locale, :api_keys_attributes, :is_registration,
                  :members_attributes, :groups_attributes, :email_no_domain

  #############################
  ## Validations

  validates :permalink, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true, :if => lambda { |o| o.is_user? }
  validates :email, presence: true
  validates :residence, presence: true
  validates :affiliation, presence: true, :if => lambda { |o| o.is_user? }
  validates :age_group, inclusion: { in: AGE_GROUP.keys }, :if => lambda { |o| o.is_user? }
  validates :status, inclusion: { in: STATUS.keys }
  validates :status_other, presence: true, :if => lambda { |o| o.status == 8 }
  validates :account, :numericality => { :equal_to => 1 }, :if => lambda { |o| o.is_user? && o.is_registration.present?}
  validates :facebook_account, :inclusion => { :in => ["0", "1"] }, :if => lambda { |o| o.is_user? && o.is_registration.present? }
  validates :website_url, format: { with: URI::regexp(%w(http https)) }, if: Proc.new { |o| o.website_url.present? }
  validates_attachment_content_type :avatar, content_type: /\Aimage/
  validates_attachment_file_name :avatar, matches: [/png\Z/, /jpe?g\Z/]

  ####################
  ## Callbacks

  before_validation :set_permalink
  before_create :create_nickname
  before_save :create_email_no_domain

  def set_permalink
    self.permalink = self.name if self.permalink.nil? || self.permalink.empty?
    return true
  end

  def create_nickname
    self.nickname = self.email.split('@')[0] if self.nickname.blank? && self.email.present?
    return true
  end

  # email_no_domain is used in the search for collaborators
  # so people cannot search using domain name to guess their email addresses
  def create_email_no_domain
    self.email_no_domain = self.email.split('@').first if self.email.present? && self.email_no_domain.nil?
    return true
  end


  #############################
  ## Scopes

  def self.no_admins
    ne(role: ROLES[:admin])
  end

  def self.find_for_facebook_oauth(auth, params) #, signed_in_resource=nil
     Rails.logger.debug("-----------------------------------#{params.inspect}---------#{params["first_name"].present?} #{params[:first_name]} #{auth.info.first_name}")
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


  # override the login query to make sure it only looks at users and not groups
  def self.find_for_authentication(warden_conditions)
    where(:is_user => true, :email => warden_conditions[:email]).first
  end

  # get the notification language locale for a user
  def self.get_notification_language_locale(id)
    x = only(:notification_locale).find(id)
    return x.present? ? x.notification_locale.to_sym : I18n.default_locale
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

  # if user logged in with omniauth, password is not required
  def password_required?
    super && provider.blank?
  end

  def agreement(dataset_id, dataset_type, dataset_locale, download_type)
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
        download_type: download_type
      })
    a.valid?
  end

  # determine if user belongs to any groups
  def belongs_to_groups?
    self.groups.count > 0
  end

  def user_group_list
    x = [self]
    x << self.groups.map{|x| x.group}
    return x.flatten
  end

  # determine if group has members
  def has_members?
    self.members.count > 0
  end

  def group_member_list
    x = [self]
    x << self.members.map{|x| x.member}
    return x.flatten
  end


  # get the number of datasets this user has
  def dataset_count
    Dataset.count_by_user(self.id)
  end

  # override devise method to indicate that password is not needed for group
  def password_required?
    is_user? && (!persisted? || !password.nil? || !password_confirmation.nil?)
  end

  def status_name
    if self.status.present?
      I18n.t("user.status.#{STATUS[self.status]}")
    end
  end

  # get list of users that match the passed in query
  # - user must not be this user or one of its members
  # - search in user name and email
  def invitation_search(q, limit=10)
    if q.present? and q.length > 1
      already_exists_ids = []
      already_exists_emails = []
      # add owner
      already_exists_ids << self.id
      # add colaborators
      if self.members.present?
        already_exists_ids << self.members.map{|x| x.member_id}
      end
      # add invitations
      pending = Invitation.pending_from_user(self.id)
      if pending.present?
        already_exists_emails << pending.map{|x| x.to_email}
      end

      already_exists_ids.flatten!
      already_exists_emails.flatten!

      users = User.any_of({first_name: /#{q}/i}, {last_name: /#{q}/i}, {email_no_domain: /#{q}/i}).limit(limit)
      if already_exists_ids.present? && already_exists_emails.present?
        users = users.not_in({id: already_exists_ids.uniq}, {email: already_exists_emails.uniq})
      elsif already_exists_ids.present?
        users = users.not_in({id: already_exists_ids.uniq})
      elsif already_exists_emails.present?
        users = users.not_in({email: already_exists_emails.uniq})
      end

      return users
    end
  end



end

class Interview
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  # belongs_to :user

  #############################

    AGE_GROUP = { 1 => '17-24', 2 => '25-34', 3 => '35-44', 4 => '45-54', 5 => '55-64', 6 => 'above'}
    STATUS = { 1 => 'researcher',
               2 => 'student',
               3 => 'journalist',
               4 => 'ngo',
               5 => 'government_official',
               6 => 'international_organization',
               7 => 'private_sector',
               8 => 'other' }

  #############################

  field :first_name, type: String
  field :last_name, type: String
  field :age_group, type: Integer
  field :residence, type: String
  field :email, type: String
  field :affiliation, type: String
  field :status, type: Integer
  field :status_other, type: String
  field :description, type: String

  #############################

  attr_accessor :terms
  attr_accessible :first_name, :last_name, :age_group, :residence,
                  :email, :affiliation, :status, :status_other, :description, :terms


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
  validates :terms, :numericality => { :equal_to => 1 }


  #############################
  ## Scopes
  
  def self.test
    puts STATUS.inspect
  end


end

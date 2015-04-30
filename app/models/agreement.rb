class Agreement
  include Mongoid::Document
  include Mongoid::Timestamps

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

  field :file, type: String
  #############################

  attr_accessor :terms
  attr_accessible :first_name, :last_name, :age_group, :residence,
                  :email, :affiliation, :status, :status_other, :description, :file, :terms

    STATUS = { 1 => 'researcher',
               2 => 'student',
               3 => 'journalist',
               4 => 'ngo',
               5 => 'government_official',
               6 => 'international_organization',
               7 => 'private_sector',
               8 => 'other' }
  #############################
  ## Validations

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :age_group, inclusion: { in: [1,2,3,4,5,6] }
  validates :residence, presence: true
  validates :email, presence: true
  validates :affiliation, presence: true
  validates :status, inclusion: { in: STATUS.keys }
  validates_presence_of :status_other, :if => lambda { |o| o.status == 8 }
  validates :file, presence: true
  validates :terms, :numericality => { :equal_to => 1 }

end

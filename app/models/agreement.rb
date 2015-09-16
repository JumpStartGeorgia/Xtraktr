class Agreement
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################
  belongs_to :dataset

  field :first_name, type: String
  field :last_name, type: String
  field :age_group, type: Integer
  field :residence, type: String
  field :email, type: String
  field :affiliation, type: String
  field :status, type: Integer
  field :status_other, type: String
  field :description, type: String
  field :dataset_type, type: String
  field :dataset_locale, type: String
  field :download_type, type: String

  #############################
  
  attr_accessible :first_name, :last_name, :age_group, :residence,
                  :email, :affiliation, :status, :status_other, :description, :dataset_id, :dataset_type, :dataset_locale, :download_type

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
  validates_format_of  :email, with: Devise.email_regexp, allow_blank: false
  validates :affiliation, presence: true
  validates :status, inclusion: { in: STATUS.keys }
  validates_presence_of :status_other, :if => lambda { |o| o.status == 8 }
  validates :dataset_id, presence: true
  validates :dataset_type, presence: true
  validates :dataset_locale, presence: true  
  validates :download_type, :inclusion => {:in => ['public', 'admin']  }



  ####################
  ## Scopes

  def self.sorted
    order_by([[:created_at, :asc]])
  end

  ####################

  # generate a csv object for all records on file
  def self.generate_csv
    return CSV.generate do |csv_row|
      # add header
      csv_row << csv_header

      # get the dataset titles for all records
      datasets = Dataset.only_id_title_languages.in(id: pluck(:dataset_id).uniq)
      
      sorted.each do |record|
        # add row
        csv_row << record.csv_data(datasets)
      end
    end
  end


  def self.csv_header
    model = Agreement
    return [  
      model.human_attribute_name("created_at"), model.human_attribute_name("first_name"), model.human_attribute_name("last_name"), 
      model.human_attribute_name("age_group"), model.human_attribute_name("residence"), model.human_attribute_name("email"), 
      model.human_attribute_name("affiliation"), model.human_attribute_name("status"), model.human_attribute_name("description"), 
      model.human_attribute_name("dataset_id"), model.human_attribute_name("dataset_type"), model.human_attribute_name("dataset_locale"), 
      model.human_attribute_name("download_type")
    ]
  end

  def csv_data(datasets)
    dataset = datasets.select{|x| x.id.to_s == self.dataset_id.to_s}.first
    title = dataset.present? ? dataset.title : self.dataset_id

    age_group = I18n.t("user.age_group.g#{self.age_group}") if self.age_group.present?
    status = if self.status == 8
      self.status_other
    else
      I18n.t("user.status.#{STATUS[self.status]}")
    end

    return [  
      self.created_at, self.first_name, self.last_name, age_group, self.residence, 
      self.email, self.affiliation, status, self.description, 
      title, self.dataset_type, self.dataset_locale, self.download_type
    ]
  end

end

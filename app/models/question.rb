class Question
  include Mongoid::Document

  #############################

  belongs_to :shapeset

  #############################

  field :code, type: String
  field :text, type: String
  field :original_code, type: String
  field :has_code_answers, type: Boolean, default: false
  field :is_mappable, type: Boolean, default: false

  embedded_in :dataset
  embeds_many :answers do
    # these are functions that will query the answers documents

    # get the unique answer values
    def unique_values
      only(:values).map{|x| x.values}
    end

    # get the answer that has the provide value
    def with_value(value)
      where(:value => value).first
    end

  end
  accepts_nested_attributes_for :answers

  #############################
  # indexes
  index ({ :code => 1})
  index ({ :text => 1})
  index ({ :has_code_answers => 1})
  index ({ :is_mappable => 1})

  #############################
  # Validations
  validates_presence_of :code, :text, :original_code

  #############################
  attr_accessible :code, :text, :original_code, :has_code_answers, :is_mappable, :answers_attributes

  #############################

  before_save :update_flags
  before_save :check_mappable

  def update_flags
    puts "updating question flags for #{self.code}"
    self.has_code_answers = self.answers.present?

    return true
  end

  # if is_mappable changed, tell the dataset to update its flag
  def check_mappable
    if self.shapeset_id_changed?
      self.is_mappable = self.shapeset_id.present?
      self.dataset.update_mappable_flag
    end
    return true
  end

  #############################


end
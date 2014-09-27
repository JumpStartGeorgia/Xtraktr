class Dataset
  include Mongoid::Document

  field :title,       type: String
  field :explanation, type: String
  field :data,        type: Array

  # Validations
  validates_presence_of :title

end
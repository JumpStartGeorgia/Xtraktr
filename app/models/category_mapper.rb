class CategoryMapper
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################
  belongs_to :category
  belongs_to :dataset

  #############################
  attr_accessible :category_id, :dataset_id
  #############################

  # indexes
  index ({ :category_id => 1})
  index ({ :dataset_id => 1})

  #############################
  # Validations
  validates_presence_of :category_id, :dataset_id
end
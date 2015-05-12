class CategoryMapper
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################
  belongs_to :category
  belongs_to :dataset
  belongs_to :time_series

  #############################
  attr_accessible :category_id, :dataset_id, :time_series_id

  #############################

  # indexes
  index ({ :category_id => 1})
  index ({ :dataset_id => 1})
  index ({ :time_series_id => 1})

  #############################
  # Validations
  validates_presence_of :category_id
  validates_presence_of :dataset_id, unless: :time_series_id?
  validates_presence_of :time_series_id, unless: :dataset_id?
  validates_uniqueness_of :category_id, scope: [:dataset_id], if: :dataset_id?
  validates_uniqueness_of :category_id, scope: [:time_series_id], if: :time_series_id?

end
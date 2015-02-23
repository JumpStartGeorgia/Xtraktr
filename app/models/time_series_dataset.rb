class TimeSeriesDataset
  include Mongoid::Document

  #############################

  belongs_to :dataset
  embedded_in :time_series

  #############################

  field :dataset_id, type: String
  field :title, type: String
  field :sort_order, type: Integer

#  has_many :time_series_dataset_questions, dependent: :destroy

  #############################

 # accepts_nested_attributes_for :time_series_dataset_questions

  attr_accessible :dataset_id, :title, :sort_order#, :time_series_dataset_questions_attributes

end

class TimeSeriesDatasetQuestion
  include Mongoid::Document

  #############################

  belongs_to :dataset
  embedded_in :time_series_question

  #############################

  # field :dataset_id, type: String
  field :code, type: String
  field :text, type: String, localize: true

  #############################

  attr_accessible :code, :dataset_id, :text, :text_translations


end

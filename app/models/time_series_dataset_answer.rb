class TimeSeriesDatasetAnswer
  include Mongoid::Document

  #############################

  belongs_to :dataset
  embedded_in :time_series_answer

  #############################

  field :dataset_id, type: String
  field :value, type: String
  field :text, type: String, localize: true

  #############################

  attr_accessible :value, :dataset_id, :text, :text_translations

end

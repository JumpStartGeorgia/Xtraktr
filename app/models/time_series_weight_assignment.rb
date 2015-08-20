class TimeSeriesWeightAssignment
  include Mongoid::Document

  #############################

  belongs_to :dataset

  #############################
  field :code_unique_id, type: String
  field :weight_values, type: Array, default: []

  #############################
  embedded_in :time_series_weight

  #############################
  attr_accessible :dataset_id, :code_unique_id, :weight_values

  #############################
  # Validations
  validates_presence_of :code_unique_id, :dataset_id
  validates :weight_values, :presence => true, :unless => Proc.new { |x| x.weight_values.is_a?(Array) && x.weight_values.empty? }

  #############################
  # Callbacks

  #############################


end

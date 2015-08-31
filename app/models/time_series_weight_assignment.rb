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
  before_save :reset_is_default_flags


  # if this weight is marked as default, make sure no other records have this flag
  def reset_is_default_flags
    if self.is_default == true
      self.time_series.weights.get_all_but(self.id).update_all(is_default: false)
    end
  end

  #############################


end

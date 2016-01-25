class Numerical

  NUMERIC_DEFAULT_WIDTH = 10
  TYPE_VALUES = { integer: 0, float: 1}
  include Mongoid::Document

  #############################
  field :title, type: String, localize: true
  field :type, type: Integer #, default: 0 # [0: Integer, 1: Decimal]
  field :width, type: Float#, default: NUMERIC_DEFAULT_WIDTH
  field :min, type: Float
  field :max, type: Float
  field :min_range, type: Float
  field :max_range, type: Float
  field :size, type: Integer

  embedded_in :question

  #############################
  attr_accessible :type, :width, :min, :max, :title, :title_translations, :min_range, :max_range, :size

  #############################
  # Validations
  validates_presence_of :type, :width, :min, :max, :min_range, :max_range, :size

  #############################
  ## used when editing time series questions
  # def to_json
  #   {
  #     value: self.value,
  #     text: self.text,
  #     text_translations: self.text_translations,
  #     sort_order: self.sort_order,
  #     can_exclude: self.can_exclude,
  #     exclude: self.exclude
  #   }
  # end
  def integer?
    return type == TYPE_VALUES[:integer]
  end
  def float?
    return type == TYPE_VALUES[:float]
  end
end

class Numerical

  NUMERIC_DEFAULT_NUMBER_GROUP = 8

  include Mongoid::Document

  #############################
  field :title, type: String, localize: true
  field :type, type: Integer #, default: 0 # [0: Integer, 1: Decimal]
  field :size, type: Integer #, default: NUMERIC_DEFAULT_NUMBER_GROUP
  field :min, type: Float
  field :max, type: Float

  embedded_in :question

  #############################
  attr_accessible :type, :size, :min, :max, :title, :title_translations

  #############################
  # Validations
  validates_presence_of :type, :size, :min, :max

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

end

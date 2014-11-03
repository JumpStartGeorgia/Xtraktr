class Answer
  include Mongoid::Document

  field :value, type: String
  field :text, type: String
  field :can_exclude, type: Boolean, default: false
  field :sort_order, type: Integer, default: 1

  embedded_in :question

  #############################
  # indexes
  index ({ :can_exclude => 1})
  index ({ :sort_order => 1})

  #############################
  # Validations
  validates_presence_of :value, :text

  #############################
  attr_accessible :value, :text, :can_exclude, :sort_order

  #############################


end
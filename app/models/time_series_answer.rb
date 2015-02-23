class TimeSeriesAnswer < CustomTranslation
  include Mongoid::Document

  #############################

  embedded_in :time_series_question

  #############################

  field :value, type: String
  field :text, type: String, localize: true
  field :can_exclude, type: Boolean, default: false
  field :sort_order, type: Integer, default: 1
  field :exclude, type: Boolean, default: false

  #############################

  attr_accessible :value, :text, :can_exclude, :sort_order, :text_translations, :exclude


end

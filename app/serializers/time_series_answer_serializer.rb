class TimeSeriesAnswerSerializer < ActiveModel::Serializer
  attributes :value, :text, :can_exclude, :sort_order
end

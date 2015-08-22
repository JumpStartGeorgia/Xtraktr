class TimeSeriesWeightSerializer < ActiveModel::Serializer
  attributes :text, :is_default, :applies_to_all, :codes

end

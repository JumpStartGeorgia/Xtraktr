class WeightSerializer < ActiveModel::Serializer
  attributes :name, :is_default, :applies_to_all, :codes
  def name
    object.text
  end
end

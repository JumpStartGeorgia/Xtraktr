class TimeSeriesGroupSerializer < ActiveModel::Serializer
  attributes :title, :description, :items

  def items
    return_items = []
    object.arranged_items.each do |item|
      if item.class == TimeSeriesGroup
        return_items << TimeSeriesGroupSerializer.new(item)
      elsif item.class == TimeSeriesQuestion
        return_items << TimeSeriesQuestionSerializer.new(item)
      end
    end

    return return_items
  end
end

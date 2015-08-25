class GroupSerializer < ActiveModel::Serializer
  attributes :title, :description, :items

  def items
    return_items = []
    object.arranged_items.each do |item|
      if item.class == Group
        return_items << GroupSerializer.new(item)
      elsif item.class == Question
        return_items << QuestionSerializer.new(item)
      end
    end

    return return_items
  end
end

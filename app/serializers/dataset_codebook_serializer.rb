class DatasetCodebookSerializer < ActiveModel::Serializer
  attributes :id, :url, :title, :description, :source, :weights, :items

  has_many :weights

  def url
    Rails.application.routes.url_helpers.explore_data_dashboard_url(locale: I18n.locale, id: object.slug)
  end

  def weights
    object.weights
  end

  # get the questions/groups in arranged order
  def items
    return_items = []
    object.arranged_items(question_type: 'analysis', include_groups: true, include_subgroups: true, include_questions: true).each do |item|
      if item.class == Group
        return_items << GroupSerializer.new(item)
      elsif item.class == Question
        return_items << QuestionSerializer.new(item)
      end
    end
    return return_items
  end

end

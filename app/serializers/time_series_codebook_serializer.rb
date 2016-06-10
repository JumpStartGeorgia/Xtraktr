class TimeSeriesCodebookSerializer < ActiveModel::Serializer
  attributes :id, :url, :title, :description, :weights, :items

  has_many :weights

  def url
    Rails.application.routes.url_helpers.explore_time_series_dashboard_url(locale: I18n.locale, owner_id: object.owner_slug, id: object.slug, protocol: "https")
  end

  def weights
    object.weights
  end

  # get the questions/groups in arranged order
  def items
    return_items = []
    object.arranged_items(question_type: 'analysis', include_groups: true, include_subgroups: true, include_questions: true).each do |item|
      if item.class == TimeSeriesGroup
        return_items << TimeSeriesGroupSerializer.new(item)
      elsif item.class == TimeSeriesQuestion
        return_items << TimeSeriesQuestionSerializer.new(item)
      end
    end
    return return_items
  end

end

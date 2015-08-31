class DatasetCatalogSerializer < ActiveModel::Serializer
  attributes :id, :url, :title, :description, :source,
              :start_gathered_at, :end_gathered_at, :released_at, :public_at,
              :total_responses, :analyzable_questions, :is_weighted

  def url
    Rails.application.routes.url_helpers.explore_data_dashboard_url(locale: I18n.locale, owner_id: object.owner_slug, id: object.slug)
  end

  def total_responses
    object.stats.data_records
  end

  def analyzable_questions
    object.stats.public_questions_analyzable
  end

  def is_weighted
    object.is_weighted?
  end
end

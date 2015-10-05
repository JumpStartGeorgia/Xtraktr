class DatasetQuestionSerializer < ActiveModel::Serializer
  attributes :id, :url, :title, :description, :source, :source_url, :donor,
      :start_gathered_at, :end_gathered_at, :released_at, :public_at,
      :total_responses, :analyzable_questions, :is_weighted,
      :is_mappable, :categories, :countries,
      :languages, :default_language, :methodology,
      :license

      has_many :reports


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

  def categories
    object.categories.map{|x| x.name}
  end

  def countries
    object.countries.map{|x| x.name}
  end

  def reports
    object.reports.sorted
  end

  def license
    if object.license_title.present?
      {
        title: object.license_title,
        description: object.license_description,
        url: object.license_url
      }
    else
      nil
    end
  end
end

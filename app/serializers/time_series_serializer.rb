class TimeSeriesSerializer < ActiveModel::Serializer
  attributes :id, :url, :title, :dates_included,
      :description, :public_at, :languages, :default_language

  has_many :datasets

  def url
    Rails.application.routes.url_helpers.explore_time_series_dashboard_url(locale: I18n.locale, id: object.slug)
  end

  def datasets
    object.datasets.sorted
  end

end

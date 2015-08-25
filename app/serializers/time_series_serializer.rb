class TimeSeriesSerializer < ActiveModel::Serializer
  attributes :id, :url, :title, :dates_included,
      :description, :public_at,
      :is_weighted, :categories,
      :languages, :default_language,
      :license_title, :license_description, :license_url

  has_many :datasets

  def url
    Rails.application.routes.url_helpers.explore_time_series_dashboard_url(locale: I18n.locale, id: object.slug)
  end

  def datasets
    object.datasets.sorted
  end

  def is_weighted
    object.is_weighted?
  end

  def categories
    object.categories.map{|x| x.name}
  end


end

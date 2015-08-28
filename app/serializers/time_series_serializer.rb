class TimeSeriesSerializer < ActiveModel::Serializer
  attributes :id, :url, :title, :dates_included,
      :description, :public_at,
      :is_weighted, :categories, :countries,
      :languages, :default_language,
      :license

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

  def countries
    object.countries.map{|x| x.name}
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

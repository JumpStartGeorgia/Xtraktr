class TimeSeriesCatalogSerializer < ActiveModel::Serializer
  attributes :id, :url, :title, :dates_included, :public_at

  def url
    Rails.application.routes.url_helpers.explore_time_series_dashboard_url(locale: I18n.locale, id: object.slug)
  end


end

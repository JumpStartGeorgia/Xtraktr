class TimeSeriesCatalogSerializer < ActiveModel::Serializer
  attributes :id, :url, :title, :dates_included, :public_at, :is_weighted

  def url
    Rails.application.routes.url_helpers.explore_time_series_dashboard_url(locale: I18n.locale, owner_id: object.owner_slug, id: object.slug, protocol: "https")
  end

  def is_weighted
    object.is_weighted?
  end


end

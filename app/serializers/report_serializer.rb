class ReportSerializer < ActiveModel::Serializer
  attributes :title, :summary, :language, :released_at, :file_type, :url

  def language
    object.language.name
  end

  def file_type
    object.file_extension.upcase
  end

  # hack - use root url to get base url, but have to remove locale
  def url
    Rails.application.routes.url_helpers.root_url(locale: I18n.locale).gsub("/#{I18n.locale}", '') + object.file.url
  end
end

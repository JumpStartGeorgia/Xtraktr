class TimeSeriesCatalogSerializer < ActiveModel::Serializer
  attributes :id, :title, :dates_included, :public_at
end

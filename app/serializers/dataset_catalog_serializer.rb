class DatasetCatalogSerializer < ActiveModel::Serializer
  attributes :id, :title, :source, :start_gathered_at, :end_gathered_at, :released_at, :public_at

end

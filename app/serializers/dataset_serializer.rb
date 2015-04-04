class DatasetSerializer < ActiveModel::Serializer
  attributes :id, :title, :source, :source_url, :description, 
      :start_gathered_at, :end_gathered_at, :released_at, :public_at, 
      :is_mappable, :languages, :default_language, :methodology

end

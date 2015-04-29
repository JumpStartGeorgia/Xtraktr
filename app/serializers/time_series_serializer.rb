class TimeSeriesSerializer < ActiveModel::Serializer
  attributes :id, :title, :dates_included,  
      :description, :public_at, :languages, :default_language

  has_many :datasets

  def datasets
    object.datasets.sorted
  end  

end

class TimeSeriesSerializer < ActiveModel::Serializer
  attributes :id, :title, :public_at, 
      :description, :languages, :default_language

  has_many :datasets

  def datasets
    object.datasets.sorted
  end  

end

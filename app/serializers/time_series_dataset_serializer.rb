class TimeSeriesDatasetSerializer < ActiveModel::Serializer
  attributes :dataset_id, :label, :title

  def label
    object.title
  end

  def title
    object.dataset.title
  end
end

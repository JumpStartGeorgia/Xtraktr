class TimeSeriesDataset
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  belongs_to :dataset
  belongs_to :time_series

  #############################

  field :title, type: String
  field :sort_order, type: Integer

  #############################

  attr_accessible :dataset_id, :time_series_id, :title, :sort_order

  #############################
  # Indexes
  index ({ :dataset_id => 1})
  index ({ :time_series_id => 1})
  index ({ :sort_order => 1, :title => 1 })

  #############################
  # Validations
  validates_presence_of :dataset_id, :time_series_id, :title, :sort_order


  #############################

  # get only the time series id and title
  def time_series_id_title
    TimeSeries.only_id_title.find(self.time_series_id)
  end

  # get time series permalink
  def time_series_permalink
    x = TimeSeries.only(:_slugs).find(self.time_series_id)
    if x.present? && x.slug.present?
      x.slug
    else
      self.time_series_id
    end
  end

  # get time series owner
  def time_series_owner
    x = TimeSeries.only(:user_id).find(self.time_series_id)
    if x.present?
      x.owner
    end
  end

  # get dataset permalink
  def dataset_permalink
    x = Dataset.only(:_slugs).find(self.dataset_id)
    if x.present? && x.slug.present?
      x.slug
    else
      self.dataset_id
    end
  end

  # get dataset owner
  def dataset_owner
    x = Dataset.only(:user_id).find(self.dataset_id)
    if x.present?
      x.owner
    end
  end


  def dataset_title
    x = Dataset.only_id_title_languages.find(self.dataset_id)
    if x.present?
      return x.title
    else
      return nil
    end
  end

end

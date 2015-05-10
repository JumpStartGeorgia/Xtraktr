class Highlight
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  belongs_to :time_series
  belongs_to :dataset


  #############################

  field :embed_id, type: String
  field :show_home_page, type: Boolean, default: false
  field :visual_type, type: Integer

  VISUAL_TYPES = {pie_chart: 1, crosstab_chart: 2, line_chart: 3, map: 4}

  #############################
  attr_accessible :dataset_id, :time_series_id, :embed_id, :show_home_page, :visual_type

  #############################
  # indexes
  index ({ :dataset_id => 1})
  index ({ :time_series_id => 1})
  index ({ :show_home_page => 1})

  #############################
  # Validations
  validates_presence_of :embed_id, :visual_type
  validates_presence_of :dataset_id, unless: :time_series_id?
  validates_presence_of :time_series_id, unless: :dataset_id?
  validates_uniqueness_of :embed_id, scope: [:dataset_id], if: :dataset_id?
  validates_uniqueness_of :embed_id, scope: [:time_series_id], if: :time_series_id?

  #############################
  # Callbacks
  after_save :reset_show_home_page

  # if this highlight was just marked for home page, make sure no other records have this flag
  def reset_show_home_page
    if self.show_home_page_changed? && self.show_home_page == true
      Highlight.ne(id: self.id).update_all(show_home_page: false)
    end
  end

  #############################
  # Scopes

  # get all highlights for a dataset
  def self.by_dataset(dataset_id)
    where(dataset_id: dataset_id)
  end

  # get all highlights for a time series
  def self.by_time_series(time_series_id)
    where(time_series_id: time_series_id)
  end

  # get all highlights that are not marked for home page
  def self.with_out_home_page
    where(show_home_page: false)
  end

  # get the required home page highlight and random highlights until the limit is reached
  def self.for_home_page(limit=2)
    items = []

    # get the required highlight
    required = where(show_home_page: true).first
    if required.present?
      items << required
    end

    # now get random highlights until reach the size of limit
    index = items.length
    while index < limit
      random = with_out_home_page.skip(rand(Highlight.count)).first

      # make sure random is not already in items
      if random.present? && !items.include?(random)
        items << random
        index += 1 
      end
    end

    return items
  end


  #############################

  def visual_type_name
    VISUAL_TYPES.keys[VISUAL_TYPES.values.index(self.visual_type)].to_s
  end

  # get the dataset/time series title
  def title
    if self.dataset_id.present?
      self.dataset.title
    elsif self.time_series_id.present?
      self.time_series.title
    end
  end

end
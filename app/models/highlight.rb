class Highlight < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  belongs_to :time_series
  belongs_to :dataset


  #############################

  field :embed_id, type: String
  field :show_home_page, type: Boolean, default: false
  field :visual_type, type: Integer
  field :description, type: String, localize: true
  
  VISUAL_TYPES = { pie: 1, crosstab: 2, time_series: 3, map: 4, bar: 5, histogramm: 6, scatter: 7 }
  #############################
  attr_accessible :dataset_id, :time_series_id, :embed_id, :show_home_page, :visual_type, :description, :description_translations

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

  # get all highglights for public datasets and time series
  def self.public_highlights
    dataset_ids = Dataset.where(public: true).pluck(:id)
    time_series_ids = TimeSeries.where(public: true).pluck(:id)
    self.or({:dataset_id.in => dataset_ids}, {:time_series_id.in => time_series_ids}).order_by([[:created_at, :desc]])
  end

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
    count = self.public_highlights.count

    if count > 0
      # get the required highlight
      required = public_highlights.where(show_home_page: true).first
      if required.present?
        items << required
      end

      # now get random highlights until reach the size of limit
      # only look for more highlights if there are more highlights to look through
      index = items.length
      if limit-index != 0 && limit-index <= count
        while index < limit
          random = public_highlights.with_out_home_page.skip(rand(Highlight.public_highlights.count)).first

          # make sure random is not already in items
          if random.present? && !items.include?(random)
            items << random
            index += 1
          end
        end
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

  # get the dataset/time series languages
  def languages
    # if self.dataset_id.present?
    #   self.dataset.languages_sorted
    # elsif self.time_series_id.present?
    #   self.time_series.languages_sorted
    # end
    []
  end


  def question_code
    decode['question_code']
  end

  def broken_down_by_code
    decode['broken_down_by_code']
  end

  def filtered_by_code
    decode['filtered_by_code']
  end

  #############################
  ## override get methods for fields that are localized
  def description
    get_translation(self.description_translations)
  end



private

  def decode
    Rack::Utils.parse_query(Base64.urlsafe_decode64(self.embed_id))
  end
end

class TimeSeriesQuestion < CustomTranslation
  include Mongoid::Document

  #############################

  embedded_in :time_series

  #############################

  field :code, type: String
  field :original_code, type: String
  field :text, type: String, localize: true
  field :notes, type: String, localize: true
  # whether or not the answers has a can exclude
  field :has_can_exclude_answers, type: Boolean, default: false
  # which group this question belongs
  field :group_id, type: Moped::BSON::ObjectId
  # number indicating the sort order
  field :sort_order, type: Integer
  # indicate that this question is a weight
  field :is_weight, type: Boolean, default: false

  embeds_many :dataset_questions, class_name: 'TimeSeriesDatasetQuestion', cascade_callbacks: true do
    # get the record for a dataset
    def by_dataset_id(dataset_id)
      where(dataset_id: dataset_id).first
    end
  end

  embeds_many :answers, class_name: 'TimeSeriesAnswer', cascade_callbacks: true do
    # see if answers have can exclude
    def has_can_exclude?
      where(can_exclude: true).count > 0 ? true : false
    end

    # get the answer that has the provide value
    def with_value(value)
      where(:value => value).first
    end

    # get answers that must be included for analysis
    def must_include_for_analysis
      where(:can_exclude => false)
      .order_by([[:sort_order, :asc], [:text, :asc]]).to_a
    end

    def sorted
      order_by([[:sort_order, :asc], [:text, :asc]])
    end
  end

  #############################

  accepts_nested_attributes_for :dataset_questions
  accepts_nested_attributes_for :answers

  attr_accessible :code, :text, :original_code, :notes, :notes_translations, :has_can_exclude_answers,
                  :answers_attributes, :text_translations, :dataset_questions_attributes, :group_id, :sort_order, :is_weight

  #############################
  # Validations
  validates_presence_of :code, :original_code

  #############################
  ## override get methods for fields that are localized
  def text
    # if the title is not present, show the code
    x = get_translation(self.text_translations, self.time_series.current_locale, self.time_series.default_language)
    return x.present? ? x : self.original_code
  end
  def notes
    get_translation(self.notes_translations, self.time_series.current_locale, self.time_series.default_language)
  end

  #############################
  # callbacks

  before_save :update_flags

  def trigger_all_callbacks
    self.update_flags
  end

  def update_flags
    self.has_can_exclude_answers = self.answers.has_can_exclude?

    return true
  end


  #############################
  def code_with_text
    "#{self.original_code} - #{self.text}"
  end

  def group
    self.time_series.groups.find(self.group_id) if self.group_id.present?
  end

  # create json for groups
  def json_for_groups(selected=false)
    {
      id: self.id,
      code: self.code,
      original_code: self.original_code,
      text: self.text,
      selected: selected
    }
  end

  # get the weights for this question
  def weights(ignore_id=nil)
    self.time_series.weights.for_question(self.code, ignore_id)
  end

  # get the weight titles for this question
  def weight_titles(ignore_id=nil)
    return weights(ignore_id).map{|x| x.text}
  end

end

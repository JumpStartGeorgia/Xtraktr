class TimeSeriesQuestion < CustomTranslation
  include Mongoid::Document

  #############################

  embedded_in :time_series

  #############################

  field :code, type: String
  field :original_code, type: String
  field :text, type: String, localize: true
  field :notes, type: String, localize: true

  embeds_many :dataset_questions, class_name: 'TimeSeriesDatasetQuestion' do
    # get the record for a dataset
    def by_dataset_id(dataset_id)
      where(dataset_id: dataset_id).first
    end
  end

  embeds_many :answers, class_name: 'TimeSeriesAnswer' do
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

  attr_accessible :code, :text, :original_code, :notes, :notes_translations,
                  :answers_attributes, :text_translations, :dataset_questions_attributes

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


end

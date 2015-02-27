class TimeSeriesQuestion < CustomTranslation
  include Mongoid::Document

  #############################

  embedded_in :time_series

  #############################

  field :code, type: String
  field :original_code, type: String
  field :text, type: String, localize: true
  # whether or not the questions has answers
  field :has_code_answers, type: Boolean, default: false
  # whether or not the question should not be included in the analysis
  field :exclude, type: Boolean, default: false

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

    # get answers that are not excluded
    def all_for_analysis
      where(:exclude => false).to_a
    end

    # get answers that must be included for analysis
    def must_include_for_analysis
      where(:can_exclude => false, :exclude => false).to_a
    end

    def sorted
      order_by([[:sort_order, :asc], [:text, :asc]])
    end
  end

  #############################

  accepts_nested_attributes_for :dataset_questions
  accepts_nested_attributes_for :answers

  attr_accessible :code, :text, :original_code, :has_code_answers, :answers_attributes, :exclude, :text_translations, :dataset_questions_attributes

  #############################
  # Validations
  validates_presence_of :code, :original_code

end

class TimeSeriesQuestion < CustomTranslation
  include Mongoid::Document

  #############################

  embedded_in :time_series

  #############################

  field :code, type: String
  field :text, type: String, localize: true

  embeds_many :dataset_questions, class_name: 'TimeSeriesDatasetQuestion'
  embeds_many :answers, class_name: 'TimeSeriesAnswer' do
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

  attr_accessible :code, :text, :dataset_questions_attributes, :answers_attributes


end

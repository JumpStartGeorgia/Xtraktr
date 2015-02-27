class TimeSeriesAnswer < CustomTranslation
  include Mongoid::Document

  #############################

  embedded_in :time_series_question

  #############################

  field :value, type: String
  field :text, type: String, localize: true
  field :sort_order, type: Integer, default: 1

  embeds_many :dataset_answers, class_name: 'TimeSeriesDatasetAnswer' do
    # get the record for a dataset
    def by_dataset_id(dataset_id)
      where(dataset_id: dataset_id).first
    end
  end


  #############################

  accepts_nested_attributes_for :dataset_answers

  attr_accessible :value, :text, :sort_order, :text_translations, :dataset_answers_attributes


end

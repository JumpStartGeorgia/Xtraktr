class TimeSeriesDatasetQuestion < CustomTranslation
  include Mongoid::Document

  #############################

  belongs_to :dataset
  embedded_in :time_series_question

  #############################

  # field :dataset_id, type: String
  field :code, type: String
  field :text, type: String, localize: true

  #############################

  attr_accessible :code, :dataset_id, :text, :text_translations

  #############################
  ## override get methods for fields that are localized
  def text
    get_translation(self.text_translations, self.time_series_question.time_series.current_locale, self.time_series_question.time_series.default_language)
  end


end

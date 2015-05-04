class TimeSeriesQuestionSerializer < ActiveModel::Serializer
  attributes :code, :original_code, :text, :notes

  has_many :answers

  def answers
    object.answers.sorted
  end  
end

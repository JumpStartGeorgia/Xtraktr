class QuestionSerializer < ActiveModel::Serializer
  attributes :code, :original_code, :text, :is_mappable

  has_many :answers

  def answers
    object.answers.all_for_analysis
  end  
end

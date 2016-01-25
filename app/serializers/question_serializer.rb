class QuestionSerializer < ActiveModel::Serializer
  attributes :code, :original_code, :text, :notes, :is_mappable, :data_type

  def attributes(*args)
    hash = super
    hash[:descriptive_statistics] = object.descriptive_statistics if object.numerical_type?
    hash[:answers] = ActiveModel::ArraySerializer.new(object.answers.all_for_analysis, each_serializer: AnswerSerializer) if object.categorical_type?
    hash
  end
end
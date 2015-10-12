# data_type field was added to questions
# update all questions to have categorical data_value where has_code_answers_for_analysis is true

puts "------------------"
puts "DATASETS - updating datasets questions data_type field"
Dataset.each do |d|
  puts "updating #{d.title}"
  d.questions.each do |q|
    if q.has_code_answers_for_analysis
      q.data_type = Question::DATA_TYPE_VALUES[:categorical]
    else 
      q.data_type = Question::DATA_TYPE_VALUES[:unknown]
    end
  end
  d.save
end
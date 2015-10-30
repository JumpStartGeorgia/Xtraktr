# data_type field was added to questions
# update all questions to have categorical data_value where has_code_answers_for_analysis is true

puts "DATASETS - updating datasets questions data_type field, if question is categorical calculate frequency_data"
Dataset.each do |d|
  puts "updating #{d.title}"
  d.questions.each do |q|
    if q.has_code_answers
      q.data_type = Question::DATA_TYPE_VALUES[:categorical]
      items = d.data_items.with_code(q.code)
      code_data = items.data
      frequency_data = {}
      q.answers.sorted.each {|answer|
        frequency_data[answer.value] = code_data.select{|x| x == answer.value }.count
      }
      items.update_attributes({ frequency_data: frequency_data })          
    else 
      q.data_type = Question::DATA_TYPE_VALUES[:unknown]
    end
  end
  d.save
end
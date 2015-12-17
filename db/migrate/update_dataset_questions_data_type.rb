# data_type field was added to questions
# update all questions to have categorical data_value where is_analysable is true

puts "DATASETS - updating datasets questions data_type field, if question is categorical calculate frequency_data"
Dataset.each do |d|
  puts "updating #{d.title}"
  d.questions.each do |q|
    items = d.data_items.with_code(q.code)
    code_data = items.data

    if q.has_code_answers
      q.data_type = Question::DATA_TYPE_VALUES[:categorical]
      # items.unset(:grouped_data) if field was removed but document had it.
      frequency_data = {}
      total = 0
      q.answers.sorted.each {|answer|
        cnt = code_data.select{|x| x == answer.value }.count
        total += cnt
        frequency_data[answer.value] = [cnt, (cnt.to_f/code_data.length*100).round(2)]
      }
      items.update_attributes({ frequency_data: frequency_data, frequency_data_total: total })          
      q.is_analysable = q.answers.all_for_analysis.count > 0
      q.has_data_without_answers = total < code_data.select{|d| !d.nil? }.length 
    else 
      q.has_data_without_answers = code_data.select{|d| !d.nil? }.length > 0
      q.data_type = Question::DATA_TYPE_VALUES[:unknown]
      q.is_analysable = false
    end
  end
  d.save
end
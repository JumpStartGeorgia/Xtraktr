# data_type field was added to questions
# update all questions to have categorical data_value where is_analysable is true

start = Time.now

puts "DATASETS - updating datasets questions data_type field, if question is categorical calculate frequency_data"
Dataset.all.no_timeout.each do |d|
  puts "-----------------------"
  puts "updating #{d.title}"
  # only update files that are not spreadsheets since we do not know the data types in spreadsheets by default
  if ['csv', 'ods', 'xls', 'xlsx'].include?(d.file_extension)
    puts "-- spreadsheet -> skipping!"
  else
    d.questions.each do |q|
      if q.data_type == Question::DATA_TYPE_VALUES[:categorical]
        d.update_question_type(q.code, q.data_type, nil)
      elsif q.data_type == Question::DATA_TYPE_VALUES[:numerical]
        d.update_question_type(q.code, q.data_type, q.numerical)
        q.exclude = true
      else
        if q.has_code_answers
          d.update_question_type(q.code, Question::DATA_TYPE_VALUES[:categorical], nil)       
        else 
          d.update_question_type(q.code, Question::DATA_TYPE_VALUES[:unknown], nil)       
        end
      end
    end
    d.check_questions_for_changes_status = true
    d.save
    puts "it took #{Time.now-start} seconds to add the questions"  
  end
end

puts ""
puts "-----------------------"
puts "UPDATING QUESTION TYPE TOOK #{(Time.now - start).round(2)} seconds"
puts "-----------------------"
puts ""

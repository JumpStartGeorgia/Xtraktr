# has_can_exclude_answers field was added to questions
# update all questions with the correct field value

puts "------------------"
puts "DATASETS"

Dataset.each do |d|
  puts "updating #{d.title}"
  d.questions.for_analysis.each do |q|
    q.has_can_exclude_answers = q.answers.has_can_exclude?
  end

  d.save

end

puts "------------------"
puts "TIME SERIES"

TimeSeries.each do |ts|
  puts "updating #{ts.title}"
  ts.questions.each do |q|
    q.has_can_exclude_answers = q.answers.has_can_exclude?
  end

  ts.save

end

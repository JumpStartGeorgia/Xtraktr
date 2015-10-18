# update the can_download question flag to true for all questions
Dataset.all.each do |d|
  puts "Dataset #{d.title}"
  d.questions.each do |q|
    q.can_download = true
  end
  d.save
end
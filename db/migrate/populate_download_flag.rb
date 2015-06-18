
# can_download flag was added to dataset questions
# update all dataset questions that have answers to indciate that they can be downloadable
Dataset.each do |dataset|
  puts "updating #{dataset.title}"
  dataset.questions.where(has_code_answers: true).each{|q| q.can_download = true}
  dataset.save
end
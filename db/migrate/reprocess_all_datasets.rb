# data_type field was added to questions
# update all questions to have categorical data_value where is_analysable is true

start = Time.now

puts "Reprocess datasets - data_items by new fixed schema and related fields"
Dataset.all.no_timeout.each do |d|
  puts ""
  puts "-----------------------"
  puts "updating #{d.title}"
  puts "-----------------------"
  puts ""

  d.reprocess_file  
  d.save

end

puts ""
puts "-----------------------"
puts "REPROCESSING DATA TOOK #{(Time.now - start).round(2)} seconds"
puts "-----------------------"
puts ""


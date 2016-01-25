# reload the data for each dataset

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


# if the indexes do not exist, create it!
unless Dataset.__elasticsearch__.index_exists?
  puts "!! Dataset elasticsearch index does not exist - creating !!"
  Dataset.__elasticsearch__.create_index! force: true
  Dataset.import force: true
end
unless TimeSeries.__elasticsearch__.index_exists?
  puts "!! TimeSeries elasticsearch index does not exist - creating !!"
  TimeSeries.__elasticsearch__.create_index! force: true
  TimeSeries.import force: true
end
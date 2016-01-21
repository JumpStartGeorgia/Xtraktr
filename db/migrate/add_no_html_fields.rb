# add new fields for description/methodology that will have no html in them
# so search results can return better results
puts "DATASETS"
Dataset.all.no_timeout.each do |d|
  puts d.title
  d.strip_html_from_text
  d.save
end

puts ""
puts "TIME SERIES"
TimeSeries.all.no_timeout.each do |ts|
  puts ts.title
  ts.strip_html_from_text
  ts.save
end

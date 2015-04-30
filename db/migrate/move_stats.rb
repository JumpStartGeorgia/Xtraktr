# move the stats from embeded in dataset to be its own document

new_stats = Mongoid.default_session[:stats]
new_stats.find.remove_all

# remove existing stats
Dataset.all.each do |d|
  puts "unseting stats for dataset #{d.id}"
  # use unset to skip callbacks
  d.unset(:stats) # remove embedded data
end

puts "----------"

# generate new stats
Dataset.all.each do |d|
  puts "updating stats for dataset #{d.id}"
  d.update_stats
  d.save
end

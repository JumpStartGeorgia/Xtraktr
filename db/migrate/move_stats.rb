# move the stats from embeded in dataset to be in own model

new_stats = Mongoid.default_session[:stats]
new_stats.find.remove_all

# remove existing stats
Dataset.all.each do |d|
  # use unset to skip callbacks
  d.unset(:stats) # remove embedded data
end

# generate new stats
Dataset.all.each do |d|
  d.update_stats
  d.save
end

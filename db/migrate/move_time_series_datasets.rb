# move time_series_datasets from embeded in time series to be its own document

new_tsd = Mongoid.default_session[:time_series_datasets]
new_tsd.find.remove_all

# move existing reocrds and then remove embed version
TimeSeries.all.each do |ts|
  puts "-----"
  puts "time series #{ts.id}"
  # move the dataset records
  ts.attributes['datasets'].each do |d|
    puts "- moving dataset #{d['dataset_id']}"
    # add missing time series id
    d['time_series_id'] = ts.id
    # convert dataset id from string to object id
    d['dataset_id'] = Moped::BSON::ObjectId.from_string(d['dataset_id'])
    
    new_tsd.insert d
  end

  # use unset to skip callbacks
  puts '- removing embeded datasets'
  ts.unset(:datasets) # remove embedded data
end


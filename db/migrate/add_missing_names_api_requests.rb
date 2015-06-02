# update the api requests with names of datasets, time series and users if they are missing

api_requests = ApiRequest.where(dataset_title: nil, :dataset_id.exists => true)
if api_requests.present?
  puts "> need to add dataset title to #{api_requests.length} records"

  api_requests.map{|x| x.dataset_id}.uniq.each do |dataset_id|
    puts "---------------------------"
    puts "-> dataset = #{dataset_id}"
    dataset = Dataset.only_id_title_languages.find(dataset_id.to_s)
    if dataset.present?
      puts "-> found dataset"
      matches = api_requests.select{|x| x.dataset_id.to_s == dataset_id.to_s}
      if matches.present?
        puts "-> found api request matches for dataset; updating"
        ApiRequest.where(dataset_title: nil, dataset_id: dataset_id).update_all(dataset_title: dataset.title) 
      end
    end
  end
end

puts ""
puts ""

api_requests = ApiRequest.where(time_series_title: nil, :time_series_id.exists => true)
if api_requests.present?
  puts "-- need to add time series title to #{api_requests.length} records"

  api_requests.map{|x| x.time_series_id}.uniq.each do |time_series_id|
    puts "---------------------------"
    puts "-> time series = #{time_series_id}"
    ts = TimeSeries.only_id_title.find(time_series_id.to_s)
    if ts.present?
      puts "-> found time series"
      matches = api_requests.select{|x| x.time_series_id.to_s == time_series_id.to_s}
      if matches.present?
        puts "-> found api request matches for time series; updating"
        ApiRequest.where(time_series_title: nil, time_series_id: time_series_id).update_all(time_series_title: ts.title) 
      end
    end
  end
end

puts ""
puts ""

api_requests = ApiRequest.where(user_name: nil, :user_id.exists => true)
if api_requests.present?
  puts "-- need to add user name to #{api_requests.length} records"

  api_requests.map{|x| x.user_id}.uniq.each do |user_id|
    puts "---------------------------"
    puts "-> user = #{user_id}"
    user = User.find(user_id.to_s)
    if user.present?
      puts "-> found user"
      matches = api_requests.select{|x| x.user_id.to_s == user_id.to_s}
      if matches.present?
        puts "-> found api request matches for user; updating"
        ApiRequest.where(user_name: nil, user_id: user_id).update_all(user_name: user.name) 
      end
    end
  end
end
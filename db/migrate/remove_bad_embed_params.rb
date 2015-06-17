# remove permalink key from highlights

to_keep = %w(dataset_id time_series_id question_code broken_down_by_code filtered_by_code can_exclude with_title with_chart_data with_map_data language filtered_by_value visual_type broken_down_value filtered_by_value)

Highlight.each do |highlight|
  puts "----------"
  puts "highlight #{highlight.id}"
  options = Rack::Utils.parse_query(Base64.urlsafe_decode64(highlight.embed_id))

  new_options = options.dup.delete_if{|k,v| !to_keep.include?(k.to_s)}    

  if options == new_options
    puts " - embed_id is ok!"
  else
    puts " - embed_id is bad!"

    puts " -> was: #{options}"
    puts " -> now: #{new_options}"

    highlight.embed_id = Base64.urlsafe_encode64(new_options.to_query)
    highlight.save

  end

end

# remove permalink key from highlights

Highlight.each do |highlight|
  puts "----------"
  puts "highlight #{highlight.id}"
  options = Rack::Utils.parse_query(Base64.urlsafe_decode64(highlight.embed_id))

  puts options

  if options.has_key?('permalink')
    puts "- has permalink, removing"
    options.delete('permalink')
    highlight.embed_id = Base64.urlsafe_encode64(options.to_query)
    highlight.save
  end

end

# stata cannot process '.' in code values so need to replace them with _
# update the datasets that have '.' in them and then make sure the download files are regenerated

puts "============="
puts "DATASETS"
puts "============="
Dataset.each do |d|
  puts d.title
  questions = d.questions.where(:original_code => /\./)

  if questions.present?
    puts "- found #{questions.length} with '.'"
    # update the questions
    questions.each do |q|
      q.original_code = q.original_code.gsub('.', '_')
      
      # update the data item for this question
      di = d.data_items.with_code(q.code)
      if di.present?
        di.original_code = q.original_code.gsub('.', '_')  
        di.save      
      end
    end

    # mark the dataset to re-create download files
    d.reset_download_files = true

    d.save

  end
end


puts ""
puts "============="
puts "============="
puts ""

puts "============="
puts "TIME SERIES"
puts "============="
TimeSeries.each do |ts|
  puts ts.title

  questions = ts.questions.where(:original_code => /\./)

  if questions.present?
    puts "- found #{questions.length} with '.'"
    # update the questions
    questions.each do |q|
      q.original_code = q.original_code.gsub('.', '_')
    end

    ts.save
  end

end

# update all time series questions so that they have a record for every dataset, even if the dataset does not have a matching question
# - this is needed so user can add a question at a later time.

TimeSeries.all.each do |ts|
  puts ""
  puts "-----"
  puts ts.title

  # get the ids of all datasets in this time series, sorted
  dataset_ids = ts.datasets.dataset_ids

  # for each question, if question dataset length does not = dataset_id length, add missing dataset
  ts.questions.each do |q|
    if q.dataset_questions.length != dataset_ids.length
      puts "- add missing datasets for question #{q.code}"
      dataset_ids.each do |id|
        if q.dataset_questions.select{|x| x.dataset_id == id}.length == 0
          # no match, so add it
          q.dataset_questions.create(dataset_id: id)
        end
      end
    end
  end

  puts ""
end 
dataitems = DataItem.all
count = dataitems.count
dataitems.each_with_index {|di, ii|
  puts "#{ii}/#{count}" if ii % 1000 == 0

  if di.data.present?
    data = di.data
    data.each_with_index {|d, i|
      data[i] = ProcessDataFile.clean_data_item(d)
    }
    di.save
  end
}
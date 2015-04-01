require 'csv'
require 'json'

# read in the georgia_regions_orig.json file and 
# use the region_shape_names.csv file to 
# re-write the properties to have the en and ka names
names = CSV.read('region_shape_names.csv')
json = JSON.parse(File.read('georgia_districts_orig.json'))

# for each feature, find the matching name and update the properties
json['features'].each_with_index do |feature, i|
  puts "index = #{i}"
  # get the name
  orig_name = feature['properties']['District_n']

  # look for this name in the list
  index = names.index{|x| x[1].downcase == orig_name.downcase}

  if !index.nil?
    feature['properties'] = {}
    feature['properties']['name_en'] = names[index][1]    
    feature['properties']['name_ka'] = names[index][2]    
  else
    puts "########################"
    puts "ERROR - feature #{i} with District_n of '#{orig_name}' could not be found in the CSV file"
    puts "########################"
    return
  end

  # now save the update json file
  File.open('georgia_districts.json', 'w') do |f|
    f << json.to_json
  end


  puts "wrote file to 'georgia_districts.json'"

end

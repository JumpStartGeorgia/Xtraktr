require 'csv'
require 'json'



# read in the district json file and 
# use the district_shape_names.csv file to 
# re-write the properties to have the en and ka names
names = CSV.read('district_shape_names.csv')


puts "########################"
puts "georgia_districts_2010_orig.json"
puts "########################"

json = JSON.parse(File.read('georgia_districts_2010_orig.json'))

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
end
# now save the update json file
File.open('georgia_districts_2010.json', 'w') do |f|
  f << json.to_json
end

puts "wrote file to 'georgia_districts_2010.json'"



puts ""
puts "########################"
puts "georgia_districts_2014_orig.json"
puts "########################"

json = JSON.parse(File.read('georgia_districts_2014_orig.json'))

# for each feature, find the matching name and update the properties
json['features'].each_with_index do |feature, i|
  puts "index = #{i}"
  # get the name
  orig_name = feature['properties']['En_Name']

  # look for this name in the list
  index = names.index{|x| x[1].downcase == orig_name.downcase}

  if !index.nil?
    feature['properties'] = {}
    feature['properties']['name_en'] = names[index][1]    
    feature['properties']['name_ka'] = names[index][2]    
  else
    puts "########################"
    puts "ERROR - feature #{i} with En_Name of '#{orig_name}' could not be found in the CSV file"
    puts "########################"
    return
  end
end

# now save the update json file
File.open('georgia_districts_2014.json', 'w') do |f|
  f << json.to_json
end
puts "wrote file to 'georgia_districts_2014.json'"


puts ""
puts "########################"
puts "georgia_districts_2014_orig_min.json"
puts "########################"

json = JSON.parse(File.read('georgia_districts_2014_orig_min.json'))

# for each feature, find the matching name and update the properties
json['features'].each_with_index do |feature, i|
  puts "index = #{i}"
  # get the name
  orig_name = feature['properties']['En_Name']

  # look for this name in the list
  index = names.index{|x| x[1].downcase == orig_name.downcase}

  if !index.nil?
    feature['properties'] = {}
    feature['properties']['name_en'] = names[index][1]    
    feature['properties']['name_ka'] = names[index][2]    
  else
    puts "########################"
    puts "ERROR - feature #{i} with En_Name of '#{orig_name}' could not be found in the CSV file"
    puts "########################"
    return
  end
end

# now save the update json file
File.open('georgia_districts_2014_min.json', 'w') do |f|
  f << json.to_json
end
puts "wrote file to 'georgia_districts_2014_min.json'"


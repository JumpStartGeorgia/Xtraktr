# set the urls shapefile for datasets that are mappable
# - getting the url was a function but am now storing in model

# get all datasets that are mappable
d = Dataset.are_mappable
puts "there are #{d.length} datasets that are mappable"
d.each do |dataset|
  if File.exists?(dataset.js_shapefile_file_path)
    puts " - updating #{dataset.title}"

    # make sure the urls obj exists
    dataset.create_urls_object

    # save the url
    dataset.urls.shape_file = dataset.js_shapefile_url_path

    dataset.save

  end
end

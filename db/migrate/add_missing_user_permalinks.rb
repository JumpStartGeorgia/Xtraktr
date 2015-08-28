# for users that do not have permalinks, create one
# - this is needed when switching to having dataset/time series admin files under user permalink in route
User.where(permalink: nil).each do |user|
  puts "adding permalink for #{user.name}"
  user.set_permalink
  user.save(validate: false)
end

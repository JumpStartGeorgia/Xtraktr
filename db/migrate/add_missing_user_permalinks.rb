# assign a permalink to each user using their name
User.all.each do |u|
  if u.permalink.nil?
    u.permalink = u.name
    u.save(validate: false)
    puts "adding permalink for user #{u.name}, slug = #{u.slug}"
  end
end

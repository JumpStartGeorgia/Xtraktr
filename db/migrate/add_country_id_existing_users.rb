# try to assign country id to existing users
# if cannot, just reset to nil

# first reset field name
User.collection.find.update_all('$rename' => {'residence' => 'residence_old'})

Agreement.collection.find.update_all('$rename' => {'residence' => 'country'})

c = Country.only(:id, :name)
User.all.each do |u|
  if u[:residence_old].present?
    puts "updating user #{u.name}"
    match = c.select{|x| x.name.downcase == u[:residence_old].downcase}.first
    if match.present?
      u.country_id = match.id
    else
      u.country_id = nil
    end
  end
  u.save(validate: false)
end

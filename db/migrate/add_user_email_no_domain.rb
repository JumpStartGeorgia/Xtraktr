# add email no domain to all users
User.all.each do |u|
  u.create_email_no_domain
  u.save(validate: false)
end

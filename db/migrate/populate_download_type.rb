
# download_type field was added to agreements
# update all agreements to indciate type is public
Agreement.each do |agreement|
  if agreement.download_type.nil?
    agreement.download_type = 'public'
    agreement.save(validate: false)
  end
end
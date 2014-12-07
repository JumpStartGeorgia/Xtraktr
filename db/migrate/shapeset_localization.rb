# update the shapeset data to work with the localization

locale = I18n.default_locale.to_s
count = 0
Shapeset.all.each do |shape|
  puts "----"
  shape.title_translations = {locale => shape[:title]} if !shape[:title].nil?
  shape.description_translations = {locale => shape[:description]} if !shape[:description].nil?
  shape.source_translations = {locale => shape[:source]} if !shape[:source].nil?
  shape.source_url_translations = {locale => shape[:source_url]} if !shape[:source_url].nil?
  shape.languages = [locale]
  shape.default_language = locale

  puts "shape = #{shape.inspect}"

  shape.save!
  count += 1
  puts "----"
end

puts "#{count} shapeset records were updated!"
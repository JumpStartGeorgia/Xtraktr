# update the dataset data to work with the localization

locale = I18n.default_locale.to_s
puts "locale = #{locale}"

count = 0
Dataset.all.each do |dataset|
  puts "----"
  puts "count = #{count}"
  puts "dataset id #{dataset.id}"
  dataset.title_translations = {locale => dataset[:title]} if !dataset[:title].nil?
  dataset.description_translations = {locale => dataset[:description]} if !dataset[:description].nil?
  dataset.source_translations = {locale => dataset[:source]} if !dataset[:source].nil?
  dataset.source_url_translations = {locale => dataset[:source_url]} if !dataset[:source_url].nil?
  dataset.languages = [locale]
  dataset.default_language = locale

  # go through each question
  dataset.questions.each do |question|
    question.text_translations = {locale => question[:text]} if !question[:text].nil?

    # go through each answer
    question.answers.each do |answer|
      answer.text_translations = {locale => answer[:text]} if !answer[:text].nil?
    end
  end

  dataset.save!

  count += 1
  puts "----"
end

puts "#{count} datasetset records were updated!"